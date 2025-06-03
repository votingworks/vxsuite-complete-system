#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"

# Detect whether the TPM supports sha256, falling back to sha1 if necessary
algo="sha1"
if [ "$(tpm2 pcrread sha256:0 | wc -l)" == "2" ]; then
    algo="sha256"
fi

tpm2_startauthsession -S session.ctx
tpm2_policypcr -S session.ctx -l "${algo}:0,7" --policy pcr.policy
tpm2_createprimary -C o -c primary.ctx

# Save the primary context for reuse after reboot
# First make sure nothing is in the handle we want to save our primary context
# to
tpm2_evictcontrol -Q -c 0x81000000 &> /dev/null || true
tpm2_evictcontrol -c primary.ctx 0x81000000

# Create keys
#
# Note that the key.priv file is encrypted using the symmetric key stored at
# the handle specified in primary.ctx. That symmetric key never leaves the TPM.
# See man tpm2 create and man tpm2 createprimary for more information.
#
# We explicitly set the password for the key to the empty string (-p ''). A
# password isn't necessary for our security model, but if no password is
# specified at all, OpenSSL errs when using the key.
tpm2_create -L pcr.policy -u key.pub -r key.priv -C primary.ctx -G ecc -p ''
tpm2_load -u key.pub -r key.priv -C primary.ctx -c key.ctx

# Save the keys
tpm2_evictcontrol -Q -c 0x81000001 &> /dev/null || true
tpm2_evictcontrol -c key.ctx 0x81000001

# Delete the local key files
rm -f key.pub 
shred -u key.priv


rm -f "${VX_CONFIG_ROOT}/key.pub" "${VX_CONFIG_ROOT}/key.sec"
tpm2_readpublic -c key.ctx -f PEM -o "${VX_CONFIG_ROOT}/key.pub"

chmod +r "${VX_CONFIG_ROOT}/key.pub"

# poll-book machines require the creation of endorsement and
# attestation keys used by strongswan for tpm authentication
machine_type=$(cat ${VX_CONFIG_ROOT}/machine-type 2>/dev/null)
if [[ "${machine_type}" == "poll-book" ]]; then
  ek_handle="0x81000003"
  ak_handle="0x81010003"
  echo "Setting up TPM keys for pollbook..."
  # First, create a persistent RSA endorsement key
  tpm2_evictcontrol -Q -c "${ek_handle}" &> /dev/null || true
  tpm2_createek -G rsa -c "${ek_handle}"

  # Using that key, create a persistent RSA attestation key
  tpm2_createak -C "${ek_handle}" -G rsa -s rsassa -c ak_rsa.ctx 
  tpm2_evictcontrol -Q -c "${ak_handle}" &> /dev/null || true
  tpm2_evictcontrol -c ak_rsa.ctx "${ak_handle}"
fi

