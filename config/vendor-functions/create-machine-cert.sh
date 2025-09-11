#!/usr/bin/env bash

# Requires sudo

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_FUNCTIONS_ROOT:="$(dirname "${0}")"}"
: "${VX_METADATA_ROOT:="/vx/code"}"
: "${VX_MACHINE_TYPE:="$(< "${VX_CONFIG_ROOT}/machine-type")"}"
: "${VX_MACHINE_ID:="$(< "${VX_CONFIG_ROOT}/machine-id")"}"
: "${IS_QA_IMAGE:="$(< "${VX_CONFIG_ROOT}/is-qa-image")"}"

ROOT_VX_CERT_AUTHORITY_CERT_PATH="${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/prod/vx-cert-authority-cert.pem"

USB_DRIVE_CERTS_DIRECTORY="/media/vx/usb-drive/certs"
USB_DRIVE_CSR_PATH="${USB_DRIVE_CERTS_DIRECTORY}/csr-${VX_MACHINE_ID}.pem"
USB_DRIVE_CERT_PATH="${USB_DRIVE_CERTS_DIRECTORY}/cert-${VX_MACHINE_ID}.pem"

if [[ "${VX_MACHINE_TYPE}" == "admin" || "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
    MACHINE_CERT_PATH="${VX_CONFIG_ROOT}/vx-${VX_MACHINE_TYPE}-cert-authority-cert.pem"
else
    MACHINE_CERT_PATH="${VX_CONFIG_ROOT}/vx-${VX_MACHINE_TYPE}-cert.pem"
fi

if [[ "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
    USB_DRIVE_STRONGSWAN_CSR_PATH="${USB_DRIVE_CERTS_DIRECTORY}/csr-${VX_MACHINE_ID}-strongswan.pem"
    USB_DRIVE_STRONGSWAN_CERT_PATH="${USB_DRIVE_CERTS_DIRECTORY}/cert-${VX_MACHINE_ID}-strongswan.pem"
    MACHINE_STRONGSWAN_CERT_PATH="/etc/swanctl/x509/vx-poll-book-strongswan-rsa-cert.pem"
fi

USE_STRONGSWAN_TPM_KEY="0"

function select_usb_drive_and_mount() {
    "${VX_FUNCTIONS_ROOT}/select-usb-drive-and-mount.sh"
}

function unmount_usb_drive() {
    "${VX_METADATA_ROOT}/app-scripts/unmount-usb.sh"
}

# Don't delete the entire certs directory on the USB drive, just the files relevant to the current
# machine ID
function clean_up_usb_drive() {
    mkdir -p "${USB_DRIVE_CERTS_DIRECTORY}"
    rm -rf "${USB_DRIVE_CSR_PATH}" "${USB_DRIVE_CERT_PATH}"
    if [[ "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
        rm -rf "${USB_DRIVE_STRONGSWAN_CSR_PATH}" "${USB_DRIVE_STRONGSWAN_CERT_PATH}"
    fi
}

#
# Write cert signing request(s) to USB drive
#

function get_machine_jurisdiction_from_user_input() {
    local machine_jurisdiction
    local confirm
    while true; do
        if [[ "${IS_QA_IMAGE}" == 1 ]]; then
            machine_jurisdiction="vx.test"
        else
            read -p "Enter a jurisdiction ({state-2-letter-abbreviation}.{county-town-etc}, e.g., ca.los-angeles or vx.test for test/demo machines): " machine_jurisdiction
        fi
        if [[ "${machine_jurisdiction}" =~ ^[a-z]{2}\.[a-z-]+$ ]]; then
            read -p "Confirm that the machine jurisdiction should be set to: ${machine_jurisdiction} (y/n) " confirm
            if [[ "${confirm}" = "y" ]]; then
                echo "${machine_jurisdiction}" > "${VX_CONFIG_ROOT}/machine-jurisdiction"
                break
            else
                continue
            fi
        fi
        echo -e "\e[31mExpected jurisdiction to be of the format {state-2-letter-abbreviation}.{county-town-etc}\e[0m" >&2
    done
    echo "${machine_jurisdiction}"
}

function create_machine_cert_signing_request() {
    pushd "${VX_METADATA_ROOT}/vxsuite/libs/auth/scripts" > /dev/null
    local machine_jurisdiction="${1:-}"
    if [[ -n "${machine_jurisdiction}" ]]; then
        VX_MACHINE_TYPE="${VX_MACHINE_TYPE}" \
            VX_MACHINE_ID="${VX_MACHINE_ID}" \
            VX_MACHINE_JURISDICTION="${machine_jurisdiction}" \
            USE_STRONGSWAN_TPM_KEY="${USE_STRONGSWAN_TPM_KEY}" \
            ./create-production-machine-cert-signing-request
    else
        VX_MACHINE_TYPE="${VX_MACHINE_TYPE}" \
            VX_MACHINE_ID="${VX_MACHINE_ID}" \
            ./create-production-machine-cert-signing-request
    fi
    popd > /dev/null
}

mkdir -p "${VX_CONFIG_ROOT}"

if [[ "${VX_MACHINE_TYPE}" == "admin" || "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
    MACHINE_JURISDICTION="$(get_machine_jurisdiction_from_user_input)"
fi

read -p "Insert a USB drive into the machine. Press enter once you've done so. "
select_usb_drive_and_mount
clean_up_usb_drive

echo "Writing cert signing request(s) to USB drive..."

if [[ "${VX_MACHINE_TYPE}" == "admin" || "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
    create_machine_cert_signing_request "${MACHINE_JURISDICTION}" > "${USB_DRIVE_CSR_PATH}"
else
    create_machine_cert_signing_request > "${USB_DRIVE_CSR_PATH}"
fi

# VxPollBooks need an additional cert for strongSwan using a different TPM handle
if [[ "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
    USE_STRONGSWAN_TPM_KEY="1"
    create_machine_cert_signing_request "${MACHINE_JURISDICTION}" > "${USB_DRIVE_STRONGSWAN_CSR_PATH}"
fi

unmount_usb_drive

# if [[ "${IS_QA_IMAGE}" == 1 ]]; then
#     read -p "Because we're using a QA image, and the production VotingWorks cert has been overwritten by the dev VotingWorks cert, we can auto-certify this machine using the dev VotingWorks private key. You'll be prompted to select a USB drive again. Press enter to continue. "
#     VX_PRIVATE_KEY_PATH="${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/dev/vx-private-key.pem" \
#         VX_METADATA_ROOT="${VX_METADATA_ROOT}" \
#         "${VX_FUNCTIONS_ROOT}/vx-certifier.sh"
#     read -p "You'll be prompted to select a USB drive one last time. Press enter to continue. "
# else
#     read -p "Remove the USB drive, take it to VxCertifier, and bring it back to this machine when prompted. Press enter once you've re-inserted the USB drive. "
# fi
read -p "Remove the USB drive, take it to VxCertifier, and bring it back to this machine when prompted. Press enter once you've re-inserted the USB drive. "

#
# Copy cert(s) off of USB drive to appropriate locations
#

# Applies permissions to match the permissions of other non-executable files in VX_CONFIG_ROOT
function match_vx_config_non_executable_file_permissions() {
    local file_path="${1}"
    chown vx-vendor:vx-group "${file_path}"
    chmod u=rw,g=r,o= "${file_path}"
}

while true; do
    select_usb_drive_and_mount
    if [[ -f "${USB_DRIVE_CERT_PATH}" ]]; then
        break
    fi
    read -p "Cert not found on USB drive. Double check that you've inserted the right USB drive and given it time to mount. Press enter to try again. "
done
echo "Cert found on USB drive!"

echo "Copying cert to ${MACHINE_CERT_PATH}..."
cp "${USB_DRIVE_CERT_PATH}" "${MACHINE_CERT_PATH}"
match_vx_config_non_executable_file_permissions "${MACHINE_CERT_PATH}"

if [[ "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
  echo "Copying strongSwan cert to ${MACHINE_STRONGSWAN_CERT_PATH}..."
  cp "${USB_DRIVE_STRONGSWAN_CERT_PATH}" "${MACHINE_STRONGSWAN_CERT_PATH}"
  cp "${ROOT_VX_CERT_AUTHORITY_CERT_PATH}" /etc/swanctl/x509ca/vx-cert-authority-cert.pem
fi

clean_up_usb_drive
unmount_usb_drive

#
# Perform correctness checks
#

function error_and_start_over() {
    local message="${1}"

    echo -e "\e[31m${message}\e[0m" >&2
    read -p "Press enter to start over. "
    exit 1
}

function check_cert_contains_correct_public_key() {
    local cert_path="${1}"
    local public_key_path="${2}"

    if ! openssl x509 -in "${cert_path}" -noout -pubkey | \
        diff -q "${public_key_path}" - >/dev/null; then
        error_and_start_over "Public key in ${cert_path} doesn't match public key extracted from TPM"
    fi
}

function check_cert_signed_by_correct_cert_authority() {
    local cert_path="${1}"
    local cert_authority_cert_path="${2}"

    # Note: Setting an -attime in the future allows us to accept a cert that has a start time
    # slightly in the future because the clock on VxCertifier was slightly ahead of the machine clock
    if ! openssl verify \
        -attime "$(date -d "+10 minutes" +%s)" \
        -CAfile "${cert_authority_cert_path}" "${cert_path}" >/dev/null; then
        error_and_start_over "${cert_path} was not signed by the correct cert authority or is not yet valid because of a clock mismatch"
    fi
}

check_cert_contains_correct_public_key \
    "${MACHINE_CERT_PATH}" \
    "${VX_CONFIG_ROOT}/key.pub"

check_cert_signed_by_correct_cert_authority \
    "${MACHINE_CERT_PATH}" \
    "${ROOT_VX_CERT_AUTHORITY_CERT_PATH}"

if [[ "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
    check_cert_contains_correct_public_key \
        "${MACHINE_STRONGSWAN_CERT_PATH}" \
        "${VX_CONFIG_ROOT}/vx-poll-book-strongswan-rsa-cert.pub"

    check_cert_signed_by_correct_cert_authority \
        "${MACHINE_STRONGSWAN_CERT_PATH}" \
        "${ROOT_VX_CERT_AUTHORITY_CERT_PATH}"
fi

echo "Machine cert(s) saved! You can remove the USB drive."
