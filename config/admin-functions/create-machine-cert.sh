#!/usr/bin/env bash

# Requires sudo

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_METADATA_ROOT:="/vx/code"}"
: "${VX_MACHINE_TYPE:="$(< "${VX_CONFIG_ROOT}/machine-type")"}"

if [[ "${VX_MACHINE_TYPE}" == "admin" ]]; then
    MACHINE_CERT_PATH="${VX_CONFIG_ROOT}/vx-${VX_MACHINE_TYPE}-cert-authority-cert.pem"
else
    MACHINE_CERT_PATH="${VX_CONFIG_ROOT}/vx-${VX_MACHINE_TYPE}-cert.pem"
fi
USB_CERTS_DIRECTORY="/media/vx/usb-drive/certs"
VX_IANA_ENTERPRISE_OID="1.3.6.1.4.1.59817"

# ---------- Helpers ----------

# User input helpers

function get_machine_jurisdiction_from_user_input() {
    local prompt="Enter a jurisdiction ({state-2-letter-abbreviation}.{county-or-town}, e.g. ms.warren or ca.los-angeles): "
    local validation_error_message="Expected jurisdiction to be of the format {state-2-letter-abbreviation}.{county-or-town}"
    local machine_jurisdiction
    while true; do
        read -p "${prompt}" machine_jurisdiction
        if [[ "${machine_jurisdiction}" =~ ^[a-z]{2}\.[a-z-]+$ ]]; then
            echo "${machine_jurisdiction}" > "${VX_CONFIG_ROOT}/machine-jurisdiction"
            break
        fi
        echo -e "\e[31m${validation_error_message}\e[0m" >&2
    done
    echo "${machine_jurisdiction}"
}

# USB helpers

# Returns the path to the first connected USB stick, if any. Returns an empty string if no USB
# stick is connected.
function get_usb_path() {
    lsblk /dev/disk/by-id/usb*part* --noheadings --output PATH 2> /dev/null | grep / --max-count 1
}

# Errs if no USB is mounted (or if unmounting fails for some other reason)
function unmount_usb() {
    "${VX_METADATA_ROOT}/app-scripts/unmount-usb.sh"
}

# Never errs, even if no USB is mounted
function unmount_usb_if_mounted() {
    "${VX_METADATA_ROOT}/app-scripts/unmount-usb.sh" 2> /dev/null || true
}

function mount_usb() {
    local usb_path="${1}"
    unmount_usb_if_mounted
    "${VX_METADATA_ROOT}/app-scripts/mount-usb.sh" "${usb_path}"
}

function mount_usb_if_present() {
    local usb_path="$(get_usb_path)"
    if [[ -n "${usb_path}" ]]; then
        mount_usb "${usb_path}"
    fi
}

function wait_for_usb_and_mount_once_present() {
    while true; do
        local usb_path="$(get_usb_path)"
        if [[ -n "${usb_path}" ]]; then
            mount_usb "${usb_path}"
            break
        fi
        sleep 1
    done
}

# OpenSSL helpers

function create_machine_cert_signing_request() {
    pushd "${VX_METADATA_ROOT}/vxsuite/libs/auth"
    local machine_jurisdiction="${1:-}"
    if [[ -n "${machine_jurisdiction}" ]]; then
        VX_MACHINE_TYPE="${VX_MACHINE_TYPE}" \
        VX_MACHINE_JURISDICTION="${machine_jurisdiction}" \
        ./scripts/create-production-machine-cert-signing-request
    else
        VX_MACHINE_TYPE="${VX_MACHINE_TYPE}" \
        ./scripts/create-production-machine-cert-signing-request
    fi
    popd
}

# Permissions helpers

# Applies permissions to match the permissions of other non-executable files in VX_CONFIG_ROOT
function match_vx_config_non_executable_file_permissions() {
    local file_path="${1}"
    chown vx-admin:vx-group "${file_path}"
    chmod u=rw,g=r,o= "${file_path}"
}

# ---------- Script ----------

mkdir -p "${VX_CONFIG_ROOT}"

if [[ ${VX_MACHINE_TYPE} == "admin" ]]; then
    machine_jurisdiction="$(get_machine_jurisdiction_from_user_input)"
fi

echo "Insert a USB into the machine. The USB will be auto-detected."
sleep 1
wait_for_usb_and_mount_once_present
echo "USB detected!"

echo "Writing cert signing request to USB..."
rm -rf "${USB_CERTS_DIRECTORY}"
mkdir "${USB_CERTS_DIRECTORY}"
if [[ ${VX_MACHINE_TYPE} == "admin" ]]; then
    create_machine_cert_signing_request "${machine_jurisdiction}" > "${USB_CERTS_DIRECTORY}/csr.pem"
else
    create_machine_cert_signing_request > "${USB_CERTS_DIRECTORY}/csr.pem"
fi
echo "${VX_MACHINE_TYPE}" > "${USB_CERTS_DIRECTORY}/machine-type"
unmount_usb

read -p "Remove the USB, take it to VxCertifier, and bring it back to this machine when prompted. Press enter once you've re-inserted the USB. "

while true; do
    mount_usb_if_present
    if [[ -f "${USB_CERTS_DIRECTORY}/cert.pem" ]]; then
        break
    fi
    unmount_usb_if_mounted
    read -p "Cert not found on USB. Double check that you've inserted the right USB and given it time to mount. Press enter to try again. "
done
echo "Cert found on USB!"

echo "Copying cert to ${MACHINE_CERT_PATH}..."
cp "${USB_CERTS_DIRECTORY}/cert.pem" "${MACHINE_CERT_PATH}"
match_vx_config_non_executable_file_permissions "${MACHINE_CERT_PATH}"
rm -rf "${USB_CERTS_DIRECTORY}"
unmount_usb

echo "Machine cert saved! You can remove the USB."
