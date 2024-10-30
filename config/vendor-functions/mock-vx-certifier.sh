#!/usr/bin/env bash

# A script to emulate the behavior of VxCertifier, the VotingWorks certification terminal, with a
# private key file. Should be run after create-machine-cert.sh has written a CSR to a USB drive.
#
# Usage: sudo VX_PRIVATE_KEY_PATH=/path/to/vx-private-key.pem /path/to/mock-vx-certifier.sh

set -euo pipefail

: "${VX_FUNCTIONS_ROOT:="$(dirname "${0}")"}"
# We typically set this to /vx/code, but here we optimize for use in a vxsuite-complete-system dev
# env, as that's where this is most often used. For auto-certification on QA images, we reset this
# to /vx/code.
: "${VX_METADATA_ROOT:="${VX_FUNCTIONS_ROOT}/../.."}"

SERIAL_FILE="/tmp/serial.txt"
USB_DRIVE_CERTS_DIRECTORY="/media/vx/usb-drive/certs"

rm -f "${SERIAL_FILE}"

VX_METADATA_ROOT="${VX_METADATA_ROOT}" "${VX_FUNCTIONS_ROOT}/select-usb-drive-and-mount.sh"

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
        -CA "${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/prod/vx-cert-authority-cert.pem" \
        -CAkey "${VX_PRIVATE_KEY_PATH}" \
        -CAcreateserial \
        -CAserial "${SERIAL_FILE}" \
        -in "${USB_DRIVE_CERTS_DIRECTORY}/csr.pem" \
        -days 36500 \
        -extensions v3_ca -extfile "${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/openssl.cnf" \
        -out "${USB_DRIVE_CERTS_DIRECTORY}/cert.pem"
else
    openssl x509 -req \
        -CA "${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/prod/vx-cert-authority-cert.pem" \
        -CAkey "${VX_PRIVATE_KEY_PATH}" \
        -CAcreateserial \
        -CAserial "${SERIAL_FILE}" \
        -in "${USB_DRIVE_CERTS_DIRECTORY}/csr.pem" \
        -days 36500 \
        -out "${USB_DRIVE_CERTS_DIRECTORY}/cert.pem"
fi

"${VX_METADATA_ROOT}/app-scripts/unmount-usb.sh"

rm "${SERIAL_FILE}"
