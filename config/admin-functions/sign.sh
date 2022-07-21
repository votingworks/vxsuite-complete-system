#!/bin/bash

set -euo pipefail

tpm2 startauthsession -Q -S session.ctx --policy-session
tpm2_policypcr -Q -S session.ctx -l "sha256:0,7" --policy pcr.policy

# This expects the script to be run with the data to be signed passed in via 
# a here-string, e.g. sudo ./sign.sh <<< "a string"
# It "returns" the signature on stdout by catting a temporary file. 
sigfile=$(mktemp)
tpm2 sign -Q -p session:session.ctx -c 0x81000001 -f plain -o $sigfile 

cat $sigfile
rm -f $sigfile 
