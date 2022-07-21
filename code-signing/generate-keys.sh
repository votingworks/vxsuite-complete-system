#!/bin/bash
#
# Initially taken from:
### Copyright (c) 2015 by Roderick W. Smith
### Licensed under the terms of the GPL v3
#
# modified by VotingWorks.

set -euo pipefail

echo -n "Enter a Common Name to embed in the keys: "
read NAME

echo -e "\nGenerating PK, you will be prompted for a passphrase:"
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=$NAME PK/" -keyout PK.key \
        -out PK.crt -days 3650 -sha256

echo -e "\nGenerating KEK, you will be prompted for a passphrase:"
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=$NAME KEK/" -keyout KEK.key \
        -out KEK.crt -days 3650 -sha256

echo -e "\nGenerating DB, you will be prompted for a passphrase:"
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=$NAME DB/" -keyout DB.key \
        -out DB.crt -days 3650 -sha256

echo -e "\n\nGenerating certificate requests in proper format"
openssl x509 -in PK.crt -out PK.cer -outform DER
openssl x509 -in KEK.crt -out KEK.cer -outform DER
openssl x509 -in DB.crt -out DB.cer -outform DER

GUID=`python3 -c 'import uuid; print(str(uuid.uuid1()))'`
echo $GUID > myGUID.txt

cert-to-efi-sig-list -g $GUID PK.crt PK.esl
cert-to-efi-sig-list -g $GUID KEK.crt KEK.esl
cert-to-efi-sig-list -g $GUID DB.crt DB.esl
rm -f noPK.esl
touch noPK.esl

echo -e "\nself-signing the PK"
sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" \
                  -k PK.key -c PK.crt PK PK.esl PK.auth

echo -e "\nsigning the noPK with PK"
sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" \
                  -k PK.key -c PK.crt PK noPK.esl noPK.auth

echo -e "\nsigning the KEK with PK"
sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" \
                  -k PK.key -c PK.crt KEK KEK.esl KEK.auth

echo -e "\nsigning DB with KEK"
sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" \
                  -k KEK.key -c KEK.crt db DB.esl DB.auth

chmod 0600 *.key

echo ""
echo ""
echo "PK, KEK, and DB keys and certs generated successfully!"
echo ""
