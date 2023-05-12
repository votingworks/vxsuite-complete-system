#!/usr/bin/env bash

# A temporary script to emulate the behavior of VxCertifier, the VotingWorks certification
# terminal. Should be run from the root of vxsuite-complete-system, with a USB plugged in, after
# create-machine-cert.sh has written a CSR to the USB.
#
# Usage: sudo ./config/admin-functions/mock-vx-certifier.sh

set -euo pipefail

SERIAL_FILE="/tmp/serial.txt"
USB_CERTS_DIRECTORY="/media/vx/usb-drive/certs"

function get_usb_path() {
    lsblk /dev/disk/by-id/usb*part* --noheadings --output PATH 2> /dev/null | grep / --max-count 1
}

function mount_usb() {
    ./app-scripts/unmount-usb.sh 2> /dev/null || true
    ./app-scripts/mount-usb.sh "$(get_usb_path)"
}

function unmount_usb() {
    ./app-scripts/unmount-usb.sh
}

rm -f "${SERIAL_FILE}"

mount_usb

VX_MACHINE_TYPE="$(< "${USB_CERTS_DIRECTORY}/machine-type")"
if [[
    "${VX_MACHINE_TYPE}" != "admin" &&
    "${VX_MACHINE_TYPE}" != "central-scan" &&
    "${VX_MACHINE_TYPE}" != "mark" &&
    "${VX_MACHINE_TYPE}" != "scan"
]]; then
    echo "VX_MACHINE_TYPE must be one of admin, central-scan, mark, or scan" >&2
    exit 1
fi

if [[ "${VX_MACHINE_TYPE}" = "admin" ]]; then
    openssl x509 -req \
        -CA ./vxsuite/libs/auth/certs/dev/vx-cert-authority-cert.pem \
        -CAkey ./vxsuite/libs/auth/certs/dev/vx-private-key.pem \
        -CAcreateserial \
        -CAserial "${SERIAL_FILE}" \
        -in "${USB_CERTS_DIRECTORY}/csr.pem" \
        -days 36500 \
        -extensions v3_ca -extfile ./vxsuite/libs/auth/certs/openssl.cnf \
        -out "${USB_CERTS_DIRECTORY}/cert.pem"
else
    openssl x509 -req \
        -CA ./vxsuite/libs/auth/certs/dev/vx-cert-authority-cert.pem \
        -CAkey ./vxsuite/libs/auth/certs/dev/vx-private-key.pem \
        -CAcreateserial \
        -CAserial "${SERIAL_FILE}" \
        -in "${USB_CERTS_DIRECTORY}/csr.pem" \
        -days 36500 \
        -out "${USB_CERTS_DIRECTORY}/cert.pem"
fi

unmount_usb

rm "${SERIAL_FILE}"
