#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"


set -euo pipefail 
tpm2_startauthsession -S session.ctx
tpm2_policypcr -S session.ctx -l "sha256:0,7" --policy pcr.policy
tpm2_createprimary -C o -c primary.ctx

# Save the primary context for reuse after reboot
# First make sure nothing is in the handle we want to save our primary context
# to
tpm2_evictcontrol -Q -c 0x81000000 || true 2>&1 /dev/null
tpm2_evictcontrol -c primary.ctx 0x81000000

# Create a policy
tpm2_create -L pcr.policy -u key.pub -C primary.ctx -G ecc -c key.ctx

# Save the keys
tpm2_evictcontrol -Q -c 0x81000001 || true 2>&1 /dev/null
tpm2_evictcontrol -c key.ctx 0x81000001


rm -f "${VX_CONFIG_ROOT}/key.pub" "${VX_CONFIG_ROOT}/key.sec"
tpm2_readpublic -c key.ctx -f PEM -o "${VX_CONFIG_ROOT}/key.pub"

# Make the signing key readable by vx-group
# We may want to further limit this in the future
cat "${VX_CONFIG_ROOT}/key.pub" | qrencode -t ANSI -o -
