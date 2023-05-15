#!/usr/bin/env bash

# Requires sudo

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_METADATA_ROOT:="/vx/code"}"
: "${VX_MACHINE_JURISDICTION:="$(< "${VX_CONFIG_ROOT}/machine-jurisdiction")"}"

function program_system_administrator_card() {
    pushd "${VX_METADATA_ROOT}/vxsuite/libs/auth" > /dev/null
    NODE_ENV=production \
    VX_CONFIG_ROOT="${VX_CONFIG_ROOT}" \
    VX_MACHINE_JURISDICTION="${VX_MACHINE_JURISDICTION}" \
    ./scripts/program-system-administrator-java-card
    popd > /dev/null
}

# Close any existing connections to the card reader, e.g. from the VxAdmin app
service pcscd stop > /dev/null 2>&1

while true; do
    read -p "Connect a card reader to the machine and insert a card. Press enter to program the card. "
    if program_system_administrator_card; then # Success case
        while true; do
            read -p "Would you like to program another system administrator card? (y/n) " choice
            if [[ "${choice}" = "y" || "${choice}" = "n" ]]; then
                break
            fi
        done
        if [[ "${choice}" = "y" ]]; then
            continue
        else
            break
        fi
    else # Error case
        echo -n "Let's try again. "
    fi
done
