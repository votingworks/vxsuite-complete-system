#!/usr/bin/env bash

# Requires sudo

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_FUNCTIONS_ROOT:="$(dirname "${0}")"}"
: "${VX_METADATA_ROOT:="/vx/code"}"
: "${VX_MACHINE_TYPE:="$(< "${VX_CONFIG_ROOT}/machine-type")"}"
: "${VX_MACHINE_ID:="$(< "${VX_CONFIG_ROOT}/machine-id")"}"
: "${IS_QA_IMAGE:="$(< "${VX_CONFIG_ROOT}/is-qa-image")"}"

if [[ "${VX_MACHINE_TYPE}" == "admin" ]]; then
    MACHINE_CERT_PATH="${VX_CONFIG_ROOT}/vx-${VX_MACHINE_TYPE}-cert-authority-cert.pem"
else
    MACHINE_CERT_PATH="${VX_CONFIG_ROOT}/vx-${VX_MACHINE_TYPE}-cert.pem"
fi
USB_DRIVE_CERTS_DIRECTORY="/media/vx/usb-drive/certs"
VX_IANA_ENTERPRISE_OID="1.3.6.1.4.1.59817"

function get_machine_jurisdiction_from_user_input() {
    local machine_jurisdiction
    local confirm
    while true; do
        if [[ "${IS_QA_IMAGE}" == 1 ]]; then
            machine_jurisdiction="vx.test"
        else
            read -p "Enter a jurisdiction ({state-2-letter-abbreviation}.{county-or-town}, e.g. ms.warren or ca.los-angeles): " machine_jurisdiction
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
        echo -e "\e[31mExpected jurisdiction to be of the format {state-2-letter-abbreviation}.{county-or-town}\e[0m" >&2
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
            ./create-production-machine-cert-signing-request
    else
        VX_MACHINE_TYPE="${VX_MACHINE_TYPE}" \
            VX_MACHINE_ID="${VX_MACHINE_ID}" \
            ./create-production-machine-cert-signing-request
    fi
    popd > /dev/null
}

function unmount_usb_drive() {
    "${VX_METADATA_ROOT}/app-scripts/unmount-usb.sh"
}

# Applies permissions to match the permissions of other non-executable files in VX_CONFIG_ROOT
function match_vx_config_non_executable_file_permissions() {
    local file_path="${1}"
    chown vx-vendor:vx-group "${file_path}"
    chmod u=rw,g=r,o= "${file_path}"
}

mkdir -p "${VX_CONFIG_ROOT}"

if [[ "${VX_MACHINE_TYPE}" == "admin" ]]; then
    machine_jurisdiction="$(get_machine_jurisdiction_from_user_input)"
fi

read -p "Insert a USB drive into the machine. Press enter once you've done so. "
"${VX_FUNCTIONS_ROOT}/select-usb-drive-and-mount.sh"

echo "Writing cert signing request to USB drive..."
rm -rf "${USB_DRIVE_CERTS_DIRECTORY}"
mkdir "${USB_DRIVE_CERTS_DIRECTORY}"
if [[ "${VX_MACHINE_TYPE}" == "admin" ]]; then
    create_machine_cert_signing_request "${machine_jurisdiction}" > "${USB_DRIVE_CERTS_DIRECTORY}/csr.pem"
else
    create_machine_cert_signing_request > "${USB_DRIVE_CERTS_DIRECTORY}/csr.pem"
fi
echo "${VX_MACHINE_TYPE}" > "${USB_DRIVE_CERTS_DIRECTORY}/machine-type"
unmount_usb_drive

if [[ "${IS_QA_IMAGE}" == 1 ]]; then
    read -p "Because we're using a QA image, we can auto-certify this machine using the dev VotingWorks private key. You'll be prompted to select a USB drive again. Press enter to continue. "
    VX_PRIVATE_KEY_PATH="${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/dev/vx-private-key.pem" \
        VX_METADATA_ROOT="${VX_METADATA_ROOT}" \
        "${VX_FUNCTIONS_ROOT}/mock-vx-certifier.sh"
    read -p "You'll be prompted to select a USB drive one last time. Press enter to continue. "
else
    read -p "Remove the USB drive, take it to VxCertifier, and bring it back to this machine when prompted. Press enter once you've re-inserted the USB drive. "
fi

while true; do
    "${VX_FUNCTIONS_ROOT}/select-usb-drive-and-mount.sh"
    if [[ -f "${USB_DRIVE_CERTS_DIRECTORY}/cert.pem" ]]; then
        break
    fi
    read -p "Cert not found on USB drive. Double check that you've inserted the right USB drive and given it time to mount. Press enter to try again. "
done
echo "Cert found on USB drive!"

echo "Copying cert to ${MACHINE_CERT_PATH}..."
cp "${USB_DRIVE_CERTS_DIRECTORY}/cert.pem" "${MACHINE_CERT_PATH}"
match_vx_config_non_executable_file_permissions "${MACHINE_CERT_PATH}"
rm -rf "${USB_DRIVE_CERTS_DIRECTORY}"
unmount_usb_drive

# Quick cert correctness check
if ! openssl x509 -in "${MACHINE_CERT_PATH}" -noout -pubkey | \
    diff -q "${VX_CONFIG_ROOT}/key.pub" -; then
    echo -e "\e[31mPublic key in cert doesn't match public key extracted from TPM\e[0m" >&2
    exit 1
fi

echo "Machine cert saved! You can remove the USB drive."
