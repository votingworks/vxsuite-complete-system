#!/usr/bin/env bash

set -euo pipefail

: "${VX_FUNCTIONS_ROOT:="$(dirname "$0")"}"
: "${VX_CONFIG_ROOT:="/vx/config"}"

source "${VX_FUNCTIONS_ROOT}/../read-vx-machine-config.sh"
clear

echo -e "\e[1mWelcome to Basic Configuration\e[0m"
echo "You're going to do great"

echo
echo "Step 1: Set Machine ID"
${VX_FUNCTIONS_ROOT}/choose-vx-machine-id.sh

echo
echo "Step 2: Set Clock"
${VX_FUNCTIONS_ROOT}/set-clock.sh



