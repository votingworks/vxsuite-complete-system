#!/usr/bin/env bash

# Requires sudo

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_METADATA_ROOT:="/vx/code"}"
: "${VX_MACHINE_TYPE:="$(< "${VX_CONFIG_ROOT}/machine-type")"}"

MACHINE_CERT_PATH="${VX_CONFIG_ROOT}/vx-${VX_MACHINE_TYPE}-cert.pem"
if [[ "${VX_MACHINE_TYPE}" == "admin" ]]; then
    MACHINE_CERT_PATH="${VX_CONFIG_ROOT}/vx-${VX_MACHINE_TYPE}-cert-authority-cert.pem"
fi
MACHINE_PRIVATE_KEY_PATH="${VX_CONFIG_ROOT}/vx-${VX_MACHINE_TYPE}-private-key.pem"
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

function generate_password_with_256_bits_of_entropy() {
    # 32 bytes * 8 bits per byte = 256 bits of entropy
    openssl rand -base64 32
}

function generate_private_key() {
    local private_key_path="${1}"
    local private_key_password="${2}"
    openssl ecparam -genkey -name prime256v1 -noout | \
        openssl pkcs8 -topk8 -passout "pass:${private_key_password}" -out "${private_key_path}"
}

function construct_machine_cert_subject() {
  local machine_jurisdiction="${1:-}"
  if [[ -n "${machine_jurisdiction}" ]]; then
    echo "/C=US/ST=CA/O=VotingWorks/${VX_IANA_ENTERPRISE_OID}.1=${VX_MACHINE_TYPE}/${VX_IANA_ENTERPRISE_OID}.2=${machine_jurisdiction}/"
  else
    echo "/C=US/ST=CA/O=VotingWorks/${VX_IANA_ENTERPRISE_OID}.1=${VX_MACHINE_TYPE}/"
  fi
}

function create_machine_cert_signing_request() {
    local machine_private_key_path="${1}"
    local machine_private_key_password="${2}"
    local machine_cert_subject="${3}"
    local cert_signing_request_path="${4}"
    openssl req -new \
        -config "${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/openssl.cnf" \
        -key "${MACHINE_PRIVATE_KEY_PATH}" \
        -passin "pass:${machine_private_key_password}" \
        -subj "${machine_cert_subject}" \
        -out "${cert_signing_request_path}"
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

# TODO: Use the machine's TPM private key (generated by the generate-key.sh script) instead of a
# new key
machine_private_key_password="$(generate_password_with_256_bits_of_entropy)"
echo "${machine_private_key_password}" > "${VX_CONFIG_ROOT}/machine-private-key-password"
generate_private_key "${MACHINE_PRIVATE_KEY_PATH}" "${machine_private_key_password}"
match_vx_config_non_executable_file_permissions "${MACHINE_PRIVATE_KEY_PATH}"

if [[ ${VX_MACHINE_TYPE} == "admin" ]]; then
    machine_jurisdiction="$(get_machine_jurisdiction_from_user_input)"
    machine_cert_subject="$(construct_machine_cert_subject "${machine_jurisdiction}")"
else
    machine_cert_subject="$(construct_machine_cert_subject)"
fi

echo "Insert a USB into the machine. The USB will be auto-detected."
sleep 1
wait_for_usb_and_mount_once_present
echo "USB detected!"

echo "Writing cert signing request to USB..."
rm -rf "${USB_CERTS_DIRECTORY}"
mkdir "${USB_CERTS_DIRECTORY}"
create_machine_cert_signing_request \
    "${MACHINE_PRIVATE_KEY_PATH}" \
    "${machine_private_key_password}" \
    "${machine_cert_subject}" \
    "${USB_CERTS_DIRECTORY}/csr.pem"
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

echo "Machine cert saved!"
