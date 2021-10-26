#!/bin/bash

set -eo pipefail

if [ "$#" -ne 1 ]; then
	echo "Usage: ./mkkeys.sh <Common Name>"
	exit 1
fi

if [ "$EUID" -ne 0 ]; then
	echo "This script must run as root"
	exit 1
fi

subject="$1"

read -r -p "WARNING: This will erase the existing key $KEY. Are you sure? " really_do_it
if [ "$really_do_it" != "y" ]; then
	echo "Not overwriting existing key"
	exit 1
fi

KEY="signing.key"
CERT="cert.pem"

echo "$KEY: backing up to $KEY.orig"

if [ -r "$KEY" ]; then
	mv "$KEY" "$KEY.orig" \
		|| (echo "$KEY: unable to backup" && exit 1)
fi
if [ -r "$CERT" ]; then
	mv "$CERT" "$CERT.orig" \
		|| (echo "$CERT: unable to backup" && exit 1)
fi

openssl req \
	-new \
	-x509 \
	-newkey "rsa:2048" \
	-subj "$subject" \
	-keyout "$KEY" \
	-outform "PEM" \
	-out "$CERT" \
	-days "3650" \
	-sha256 

# Create a certificate and public key file from the PEM
echo "Creating a certificate from the key"
crt_file="${CERT/.pem/.crt}"
pub_file="${CERT/.pem/.pub}"

echo "$crt_file: Creating from $CERT"
openssl x509 \
	-outform der \
	-in "$CERT" \
	-out "$crt_file" \

echo "$pub_file: Creating from $CERT"
openssl x509 \
	-in "$CERT" \
	-noout \
	-pubkey \
	-out "$pub_file" \
