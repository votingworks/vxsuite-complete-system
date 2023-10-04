#!/usr/bin/env bash

set -euo pipefail

: "${VX_FUNCTIONS_ROOT:="$(dirname "$0")"}"
: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_METADATA_ROOT:="/vx/code"}"

source "${VX_FUNCTIONS_ROOT}/../read-vx-machine-config.sh"
clear

echo -e "\e[1mWelcome to Basic Configuration\e[0m"
echo "You're going to do great"

echo
echo -e "\e[1mStep 1: Set Machine ID\e[0m"
${VX_FUNCTIONS_ROOT}/choose-vx-machine-id.sh

echo
echo -e "\e[1mStep 2: Set Clock\e[0m"
sudo ${VX_FUNCTIONS_ROOT}/set-clock.sh

echo
echo -e "\e[1mStep 3: Record Machine Key\e[0m"
echo 'Setting up signing keys...'
sudo ${VX_FUNCTIONS_ROOT}/generate-key.sh > /dev/null
PUBLIC_KEY=$(cat "${VX_CONFIG_ROOT}/key.pub")
echo "Public Signing Key: ${PUBLIC_KEY}"
echo "Record this QR code containing the Machine ID and Public Signing Key:"
MACHINE_ID=$(< "${VX_CONFIG_ROOT}/machine-id")
echo -e "${MACHINE_ID}\n${PUBLIC_KEY}" | qrencode -t ANSI -o -

while true; do
    read -p "Confirm QR code recorded (y/n) " CONFIRM
    [[ "${CONFIRM}" = "y" ]] && break
done

echo
echo -e "\e[1mStep 4: Create Machine Cert\e[0m"
sudo ${VX_FUNCTIONS_ROOT}/create-machine-cert.sh

if [[ "${VX_MACHINE_TYPE}" = "admin" ]]; then
    echo
    echo -e "\e[1mStep 5: Program System Administrator Cards\e[0m"
    sudo ${VX_FUNCTIONS_ROOT}/program-system-administrator-cards.sh
fi

if [[ -f "${VX_CONFIG_ROOT}/RUN_BASIC_CONFIGURATION_ON_NEXT_BOOT" ]]; then
    rm -f "${VX_CONFIG_ROOT}/RUN_BASIC_CONFIGURATION_ON_NEXT_BOOT"
fi

echo
echo -e "\e[1mBasic Configuration Complete\e[0m"
read -p "You must reboot for these changes to take effect. Reboot now? (y/n) " CONFIRM
[[ "${CONFIRM}" = "y" ]] && sudo /usr/sbin/reboot
