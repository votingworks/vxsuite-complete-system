#!/bin/bash
set -euo pipefail 

if [ $# -ne 1 ]; then
    echo "Usage: ./setup-signify [directory]"
    exit 1
fi

public_path="${1}/key.pub"
secret_path="${1}/key.sec"


sudo apt -y install signify-openbsd qrencode

# clear out old keys
rm -f "${public_path}" "${secret_path}"

# Generate the keypair
signify-openbsd -G -n -p "${public_path}" -s "${secret_path}"
# Output the public key for enrollment into another device
qrencode -t UTF8 -r "${public_path}"  -o -

