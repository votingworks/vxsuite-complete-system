#!/usr/bin/env bash

# A script to create machine certs from cert signing requests (CSRs) on a USB drive, as written by
# create-machine-cert.sh.
#
# Usage:
#
# # Read from a USB drive written to by a machine
# sudo VX_PRIVATE_KEY_PATH=/path/to/vx-private-key.pem /path/to/vx-certifier.sh
#
# # Read from the specified directory
# sudo VX_PRIVATE_KEY_PATH=/path/to/vx-private-key.pem CERTS_DIRECTORY=/path/to/certs-directory /path/to/vx-certifier.sh

set -euo pipefail

USB_DRIVE_CERTS_DIRECTORY="/media/vx/usb-drive/certs"

: "${CERTS_DIRECTORY:="${USB_DRIVE_CERTS_DIRECTORY}"}"
: "${VX_FUNCTIONS_ROOT:="$(dirname "${0}")"}"
# We typically set this to /vx/code, but here we optimize for use in a vxsuite-complete-system dev
# env, as that's where this is most often used. For auto-certification on QA images, we reset this
# to /vx/code.
: "${VX_METADATA_ROOT:="${VX_FUNCTIONS_ROOT}/../.."}"

ROOT_VX_CERT_AUTHORITY_CERT_PATH="${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/prod/vx-cert-authority-cert.pem"
SERIAL_FILE="/tmp/serial.txt"

rm -f "${SERIAL_FILE}"

if [[ "${CERTS_DIRECTORY}" == "${USB_DRIVE_CERTS_DIRECTORY}" ]]; then
    VX_METADATA_ROOT="${VX_METADATA_ROOT}" "${VX_FUNCTIONS_ROOT}/select-usb-drive-and-mount.sh"
fi

for CSR_PATH in "${CERTS_DIRECTORY}"/*csr*.pem; do
    # Write certs to the same path as the CSR simply replacing "csr" in the file name with "cert"
    CERT_PATH="${CSR_PATH//csr/cert}"

    # Generate a confirmation output of the format:
    #
    # Detected CSR at /media/vx/usb-drive/csr-AD-00-00.pem
    # Machine type: admin
    # Machine ID:   AD-00-000
    # Jurisdiction: vx.test # Only present if machine type is admin or poll-book
    # Are the above parameters correct? [y/N]
    #
    echo
    echo "Detected CSR at ${CSR_PATH}"
    openssl req -in "${CSR_PATH}" -noout -subject | \
        grep -o '1\.3\.6\.1\.4\.1\.59817\.[1-9] = [^,]*' | \
        sed -E \
            -e 's/1\.3\.6\.1\.4\.1\.59817\.1 = /Machine type: /' \
            -e 's/1\.3\.6\.1\.4\.1\.59817\.6 = /Machine ID:   /' \
            -e 's/1\.3\.6\.1\.4\.1\.59817\.2 = /Jurisdiction: /'
    read -p "Are the above parameters correct? [y/N] " confirm
    if [[ "${confirm}" != 'y' && "${confirm}" != 'Y' ]]; then
        echo "Skipping without certifying"
        continue
    fi

    CMD=(
        openssl x509 -req
        -CA "${ROOT_VX_CERT_AUTHORITY_CERT_PATH}"
        -CAkey "${VX_PRIVATE_KEY_PATH}"
        -CAcreateserial
        -CAserial "${SERIAL_FILE}"
        -in "${CSR_PATH}"
        -days 36500
        -out "${CERT_PATH}"
    )

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
        echo "Successfully created and wrote cert to ${CERT_PATH}!"
    else
        echo "Failed to create cert"
        exit 1
    fi

    rm "${SERIAL_FILE}"
done

if [[ "${CERTS_DIRECTORY}" == "${USB_DRIVE_CERTS_DIRECTORY}" ]]; then
    "${VX_METADATA_ROOT}/app-scripts/unmount-usb.sh"
fi
