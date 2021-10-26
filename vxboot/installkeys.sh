#!/bin/bash
set -eo pipefail

if [ "$EUID" -ne 0 ]; then
	echo "This script must run as root"
	exit 1
fi

CERT="cert.pem"
KEY="signing.key"
TMP=$(mktemp -d)

cert-to-efi-sig-list \
		-g "$(uuidgen)" \
		"$CERT" \
		"$TMP/cert.esl" \


# Use the sign-efi-sig-list from our build so that the
# -e option exists
for key in db KEK PK; do
	echo "Signing UEFI variable $key"
	sign-efi-sig-list \
		-k "$KEY" \
		-c "$CERT" \
		"$key" \
		"$TMP/cert.esl" \
		$key.auth 
done

echo "Installing keys into firmware!"

# The order of update must be from lowest to highest
for key in db KEK PK; do
	if [ ! -r "$key.auth" ]; then
		echo "$key.auth not found: run safeboot uefi-sign-keys"
		exit 1
	fi

	echo "Installing UEFI variable $key"

	efi-updatevar -f "$key.auth" "$key" 
done
