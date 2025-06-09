#!/usr/bin/env bash

# A script to create a machine cert from a cert signing request (CSR) on a USB drive, as written by
# create-machine-cert.sh.
#
# Usage: sudo VX_PRIVATE_KEY_PATH=/path/to/vx-private-key.pem /path/to/vx-certifier.sh

set -euo pipefail

: "${VX_FUNCTIONS_ROOT:="$(dirname "${0}")"}"
# We typically set this to /vx/code, but here we optimize for use in a vxsuite-complete-system dev
# env, as that's where this is most often used. For auto-certification on QA images, we reset this
# to /vx/code.
: "${VX_METADATA_ROOT:="${VX_FUNCTIONS_ROOT}/../.."}"

SERIAL_FILE="/tmp/serial.txt"
CSR_PATH="/media/vx/usb-drive/certs/csr.pem"
CERT_PATH="/media/vx/usb-drive/certs/cert.pem"
STRONGSWAN_CSR_PATH="/media/vx/usb-drive/certs/pollbook_csr.pem"
STRONGSWAN_CERT_PATH="/media/vx/usb-drive/certs/pollbook_cert.pem"

rm -f "${SERIAL_FILE}"

VX_METADATA_ROOT="${VX_METADATA_ROOT}" "${VX_FUNCTIONS_ROOT}/select-usb-drive-and-mount.sh"

CMD=(
    openssl x509 -req
    -CA "${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/prod/vx-cert-authority-cert.pem"
    -CAkey "${VX_PRIVATE_KEY_PATH}"
    -CAcreateserial
    -CAserial "${SERIAL_FILE}"
    -in "${CSR_PATH}"
    -days 36500
    -out "${CERT_PATH}"
)

# TODO: rethink multiple cert case, this is just a quick workaround
# as a temporary solution for pollbook strongswan testing this is fine
# but what if we find ourselves with > 2 certs in the future?
if [[ -f "$STRONGSWAN_CSR_PATH" ]]; then
  echo
  echo "Found a pollbook strongswan cert request. Processing it first..."

  openssl x509 -req \
  -CA "${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/prod/vx-cert-authority-cert.pem" \
  -CAkey "${VX_PRIVATE_KEY_PATH}" \
  -CAcreateserial \
  -CAserial "${SERIAL_FILE}" \
  -in "${STRONGSWAN_CSR_PATH}" \
  -days 36500 \
  -out "${STRONGSWAN_CERT_PATH}" 

  rm "${SERIAL_FILE}"

  echo "Pollbook strongswan cert created."
fi

# Generate a confirmation output of the format:
#
# Machine type: admin
# Machine ID:   AD-00-000
# Jurisdiction: vx.test # Only present if machine type is admin or poll-book
# Are the above parameters correct? [y/N]
#
echo
openssl req -in "${CSR_PATH}" -noout -subject | \
    grep -o '1\.3\.6\.1\.4\.1\.59817\.[1-9] = [^,]*' | \
    sed -E \
        -e 's/1\.3\.6\.1\.4\.1\.59817\.1 = /Machine type: /' \
        -e 's/1\.3\.6\.1\.4\.1\.59817\.6 = /Machine ID:   /' \
        -e 's/1\.3\.6\.1\.4\.1\.59817\.2 = /Jurisdiction: /'
read -p "Are the above parameters correct? [y/N] " confirm
if [[ "${confirm}" != 'y' && "${confirm}" != 'Y' ]]; then
    echo "Exiting without certifying"
    exit 1
fi

# If certifying a VxAdmin or VxPollBook, the outputted cert needs to be a cert authority (CA) cert
# capable of issuing further certs, for smart card programming.
echo
if openssl req -in "${CSR_PATH}" -noout -subject | grep -Eq '1\.3\.6\.1\.4\.1\.59817\.1 = (admin|poll-book)'; then
    echo "Creating CA cert..."
    CMD+=(
        -extfile "${VX_METADATA_ROOT}/vxsuite/libs/auth/config/openssl.vx.cnf"
        -extensions v3_ca
    )
else
    echo "Creating cert..."
fi

if "${CMD[@]}"; then
    echo "Successfully created cert!"
else
    echo "Failed to create cert"
    exit 1
fi

"${VX_METADATA_ROOT}/app-scripts/unmount-usb.sh"

rm "${SERIAL_FILE}"
