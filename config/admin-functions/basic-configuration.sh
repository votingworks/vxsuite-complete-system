#!/usr/bin/env bash

set -euo pipefail

: "${VX_FUNCTIONS_ROOT:="$(dirname "$0")"}"
: "${VX_CONFIG_ROOT:="/vx/config"}"

source "${VX_FUNCTIONS_ROOT}/../read-vx-machine-config.sh"
clear

echo -e "\e[1mWelcome to Basic Configuration\e[0m"
echo "You're going to do great"

echo
echo -e "\e[1mStep 1: Set Machine ID\e[0m"
${VX_FUNCTIONS_ROOT}/choose-vx-machine-id.sh

echo
echo -e "\e[1mStep 2: Set Clock\e[0m"
${VX_FUNCTIONS_ROOT}/set-clock.sh

echo
echo -e "\e[1mStep 3: Record Machine Metadata\e[0m"


echo
echo -e "\e[1mBasic Configuration Complete\e[0m"
read -p "You must reboot for these changes to take effect. Reboot now? (y/n) " CONFIRM
[[ "${CONFIRM}" = "y" ]] && sudo reboot