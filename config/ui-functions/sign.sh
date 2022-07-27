#!/bin/bash

set -euo pipefail
# First detect whether the TPM supports sha1 or sha256
algo="sha256"
if [ $(tpm2 pcrread sha1:0 | wc -l) == 2 ]; then
    algo="sha1"
fi

tpm2 startauthsession -Q -S session.ctx --policy-session
tpm2_policypcr -Q -S session.ctx -l "${algo}:0,7" --policy pcr.policy

# This expects the script to be run with the data to be signed passed in via 
# a here-string, e.g. sudo ./sign.sh <<< "a string"
# It "returns" the signature on stdout by catting a temporary file. 
sigfile=$(mktemp)
tpm2 sign -Q -p session:session.ctx -c 0x81000001 -f plain -o $sigfile 

cat $sigfile
rm -f $sigfile 
