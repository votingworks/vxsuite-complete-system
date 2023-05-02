#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"


set -euo pipefail 

# First detect whether the TPM supports sha1 or sha256
algo="sha256"
if [ $(tpm2 pcrread sha1:0 | wc -l) == 2 ]; then
    algo="sha1"
fi

tpm2_startauthsession -S session.ctx
tpm2_policypcr -S session.ctx -l "${algo}:0,7" --policy pcr.policy
tpm2_createprimary -C o -c primary.ctx

# Save the primary context for reuse after reboot
# First make sure nothing is in the handle we want to save our primary context
# to
tpm2_evictcontrol -Q -c 0x81000000 || true 2>&1 > /dev/null
tpm2_evictcontrol -c primary.ctx 0x81000000

# Create keys
#
# Note that the key.priv file is encrypted using the symmetric key stored at
# the handle specified in primary.ctx. That symmetric key never leaves the TPM.
# See man tpm2 create and man tpm2 createprimary for more information.
tpm2_create -L pcr.policy -u key.pub -r key.priv -C primary.ctx -G ecc 
tpm2_load -u key.pub -r key.priv -C primary.ctx -c key.ctx

# Save the keys
tpm2_evictcontrol -Q -c 0x81000001 || true 2>&1 > /dev/null
tpm2_evictcontrol -c key.ctx 0x81000001

# Delete the local key files
rm -f key.pub 
shred -u key.priv


rm -f "${VX_CONFIG_ROOT}/key.pub" "${VX_CONFIG_ROOT}/key.sec"
tpm2_readpublic -c key.ctx -f PEM -o "${VX_CONFIG_ROOT}/key.pub"

chmod +r "${VX_CONFIG_ROOT}/key.pub"

cat "${VX_CONFIG_ROOT}/key.pub" | qrencode -t ANSI -o -
