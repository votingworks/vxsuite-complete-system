#!/usr/bin/env bash

# Requires sudo
# TODO: With the introduction of pollbook certs, we are duplicating
# some aspects of cert creation / validation. That's fine for now, but
# if this pattern continues, we should consider whether to make this
# more flexible with less duplication

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_FUNCTIONS_ROOT:="$(dirname "${0}")"}"
: "${VX_METADATA_ROOT:="/vx/code"}"
: "${VX_MACHINE_TYPE:="$(< "${VX_CONFIG_ROOT}/machine-type")"}"
: "${VX_MACHINE_ID:="$(< "${VX_CONFIG_ROOT}/machine-id")"}"
: "${IS_QA_IMAGE:="$(< "${VX_CONFIG_ROOT}/is-qa-image")"}"

USE_STRONGSWAN_TPM_KEY="0"

if [[ "${VX_MACHINE_TYPE}" == "admin" || "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
    MACHINE_CERT_PATH="${VX_CONFIG_ROOT}/vx-${VX_MACHINE_TYPE}-cert-authority-cert.pem"
else
    MACHINE_CERT_PATH="${VX_CONFIG_ROOT}/vx-${VX_MACHINE_TYPE}-cert.pem"
    if [[ "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
      STRONGSWAN_X509_PATH="/etc/swanctl/x509/vx-poll-book-strongswan-rsa-cert.pem"
      STRONGSWAN_CA_PATH="/etc/swanctl/x509ca/vx-cert-authority-cert.pem"
    fi
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

if [[ "${VX_MACHINE_TYPE}" == "admin" || "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
    machine_jurisdiction="$(get_machine_jurisdiction_from_user_input)"
fi

read -p "Insert a USB drive into the machine. Press enter once you've done so. "
"${VX_FUNCTIONS_ROOT}/select-usb-drive-and-mount.sh"

echo "Writing cert signing request to USB drive..."
rm -rf "${USB_DRIVE_CERTS_DIRECTORY}"
mkdir "${USB_DRIVE_CERTS_DIRECTORY}"
if [[ "${VX_MACHINE_TYPE}" == "admin" || "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
    create_machine_cert_signing_request "${machine_jurisdiction}" > "${USB_DRIVE_CERTS_DIRECTORY}/csr.pem"
    
    # Pollbooks need an additional cert for strongswan using a different TPM handle
    if [[ "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
      USE_STRONGSWAN_TPM_KEY="1"
      create_machine_cert_signing_request "${machine_jurisdiction}" > "${USB_DRIVE_CERTS_DIRECTORY}/vx-poll-book-strongswan-csr.pem"
    fi
else
    create_machine_cert_signing_request > "${USB_DRIVE_CERTS_DIRECTORY}/csr.pem"
fi
echo "${VX_MACHINE_TYPE}" > "${USB_DRIVE_CERTS_DIRECTORY}/machine-type"
unmount_usb_drive

if [[ "${IS_QA_IMAGE}" == 1 ]]; then
    read -p "Because we're using a QA image, and the production VotingWorks cert has been overwritten by the dev VotingWorks cert, we can auto-certify this machine using the dev VotingWorks private key. You'll be prompted to select a USB drive again. Press enter to continue. "
    VX_PRIVATE_KEY_PATH="${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/dev/vx-private-key.pem" \
        VX_METADATA_ROOT="${VX_METADATA_ROOT}" \
        "${VX_FUNCTIONS_ROOT}/vx-certifier.sh"
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

if [[ "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
  echo "Copying strongswan cert to ${STRONGSWAN_X509_PATH}..."
  cp "${USB_DRIVE_CERTS_DIRECTORY}/vx-poll-book-strongswan-cert.pem" "${STRONGSWAN_X509_PATH}"
  cp "${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/prod/vx-cert-authority-cert.pem" "${STRONGSWAN_CA_PATH}"
fi

rm -rf "${USB_DRIVE_CERTS_DIRECTORY}"
unmount_usb_drive

# Cert correctness check 1
if ! openssl x509 -in "${MACHINE_CERT_PATH}" -noout -pubkey | \
    diff -q "${VX_CONFIG_ROOT}/key.pub" -; then
    echo -e "\e[31mPublic key in machine cert doesn't match public key extracted from TPM\e[0m" >&2
    read -p "Press enter to start over. "
    exit 1
fi
#
# Cert correctness check 1 for pollbook
if [[ "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
  if ! openssl x509 -in "${STRONGSWAN_X509_PATH}" -noout -pubkey | \
      diff -q "${VX_CONFIG_ROOT}/vx-poll-book-strongswan-rsa-cert.pub" -; then
      echo -e "\e[31mPublic key in pollbook cert doesn't match the public key created by the TPM\e[0m" >&2
      read -p "Press enter to start over. "
      exit 1
  fi
fi

# Cert correctness check 2
# Note: Setting an -attime in the future allows us to accept a cert that has a start time slightly
# in the future because the clock on VxCertifier was slightly ahead of the machine clock
if ! openssl verify \
    -attime "$(date -d "+10 minutes" +%s)" \
    -CAfile "${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/prod/vx-cert-authority-cert.pem" "${MACHINE_CERT_PATH}" > /dev/null; then
    echo -e "\e[31mMachine cert was not signed by the correct cert authority or is not yet valid because of a clock mismatch\e[0m" >&2
    read -p "Press enter to start over. "
    exit 1
fi

# Cert correctness check 2 for pollbook
if [[ "${VX_MACHINE_TYPE}" == "poll-book" ]]; then
  if ! openssl verify \
      -attime "$(date -d "+10 minutes" +%s)" \
      -CAfile "${VX_METADATA_ROOT}/vxsuite/libs/auth/certs/prod/vx-cert-authority-cert.pem" "${STRONGSWAN_X509_PATH}" > /dev/null; then
      echo -e "\e[31mPollbook cert was not signed by the correct cert authority or is not yet valid because of a clock mismatch\e[0m" >&2
      read -p "Press enter to start over. "
      exit 1
  fi
fi

echo "Machine cert(s) saved! You can remove the USB drive."
