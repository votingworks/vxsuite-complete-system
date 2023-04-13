#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_METADATA_ROOT:="/vx/code"}"

function program_system_administrator_card() {
    # Use a subshell to ensure the cd doesn't have an effect beyond this command
    (cd "${VX_METADATA_ROOT}/vxsuite/libs/auth" &&
        NODE_ENV=production \
        VX_CONFIG_ROOT="${VX_CONFIG_ROOT}" \
        VX_MACHINE_JURISDICTION=$(< "${VX_CONFIG_ROOT}/machine-jurisdiction") \
        VX_MACHINE_PRIVATE_KEY_PASSWORD=$(< "${VX_CONFIG_ROOT}/machine-private-key-password") \
        ./scripts/program-system-administrator-java-card)
}

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
