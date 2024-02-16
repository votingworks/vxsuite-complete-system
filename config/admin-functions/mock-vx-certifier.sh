#!/usr/bin/env bash

# A temporary script to emulate the behavior of VxCertifier, the VotingWorks certification
# terminal. Should be run from the root of vxsuite-complete-system, with a USB drive plugged in,
# after create-machine-cert.sh has written a CSR to the USB drive.
#
# Usage: sudo VX_PRIVATE_KEY_PATH=/path/to/vx-private-key.pem ./config/admin-functions/mock-vx-certifier.sh

set -euo pipefail

SERIAL_FILE="/tmp/serial.txt"
USB_DRIVE_CERTS_DIRECTORY="/media/vx/usb-drive/certs"

rm -f "${SERIAL_FILE}"

VX_METADATA_ROOT="." ./config/admin-functions/select-usb-drive-and-mount.sh

VX_MACHINE_TYPE="$(< "${USB_DRIVE_CERTS_DIRECTORY}/machine-type")"
if [[
    "${VX_MACHINE_TYPE}" != "admin" &&
    "${VX_MACHINE_TYPE}" != "central-scan" &&
    "${VX_MACHINE_TYPE}" != "mark" &&
    "${VX_MACHINE_TYPE}" != "mark-scan" &&
    "${VX_MACHINE_TYPE}" != "scan"
]]; then
    echo "VX_MACHINE_TYPE must be one of admin, central-scan, mark, or scan" >&2
    exit 1
fi

if [[ "${VX_MACHINE_TYPE}" = "admin" ]]; then
    openssl x509 -req \
        -CA ./vxsuite/libs/auth/certs/prod/vx-cert-authority-cert.pem \
        -CAkey "${VX_PRIVATE_KEY_PATH}" \
        -CAcreateserial \
        -CAserial "${SERIAL_FILE}" \
        -in "${USB_DRIVE_CERTS_DIRECTORY}/csr.pem" \
        -days 36500 \
        -extensions v3_ca -extfile ./vxsuite/libs/auth/certs/openssl.cnf \
        -out "${USB_DRIVE_CERTS_DIRECTORY}/cert.pem"
else
    openssl x509 -req \
        -CA ./vxsuite/libs/auth/certs/prod/vx-cert-authority-cert.pem \
        -CAkey "${VX_PRIVATE_KEY_PATH}" \
        -CAcreateserial \
        -CAserial "${SERIAL_FILE}" \
        -in "${USB_DRIVE_CERTS_DIRECTORY}/csr.pem" \
        -days 36500 \
        -out "${USB_DRIVE_CERTS_DIRECTORY}/cert.pem"
fi

./app-scripts/unmount-usb.sh

rm "${SERIAL_FILE}"
