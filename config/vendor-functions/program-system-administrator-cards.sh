#!/usr/bin/env bash

# Requires sudo

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_METADATA_ROOT:="/vx/code"}"
: "${VX_MACHINE_JURISDICTION:="$(< "${VX_CONFIG_ROOT}/machine-jurisdiction")"}"
: "${VX_MACHINE_TYPE:="$(< "${VX_CONFIG_ROOT}/machine-type")"}"

function program_system_administrator_card() {
    # The underlying vxsuite script must be called from within vxsuite
    pushd "${VX_METADATA_ROOT}/vxsuite/libs/auth/scripts" > /dev/null
    NODE_ENV=production \
        VX_CONFIG_ROOT="${VX_CONFIG_ROOT}" \
        VX_MACHINE_JURISDICTION="${VX_MACHINE_JURISDICTION}" \
        VX_MACHINE_TYPE="${VX_MACHINE_TYPE}" \
        ./program-system-administrator-java-card
    popd > /dev/null
}

# Close any existing connections to the card reader, e.g. from the VxAdmin app
service pcscd stop > /dev/null 2>&1

# We don't need a sys admin card per VxPollBook so give the user a chance to skip
if [[ "${VX_MACHINE_TYPE}" = "poll-book" ]]; then
    while true; do
        read -r -p "Would you like to program a system administrator card? (y/n) " choice
        if [[ "${choice}" = "y" || "${choice}" = "n" ]]; then
            break
        fi
    done
    if [[ "${choice}" = "n" ]]; then
        exit 0
    fi
fi

while true; do
    read -r -p "Insert a card into the card reader. Press enter to program the card. "
    if program_system_administrator_card; then # Success case
        while true; do
            read -r -p "Would you like to program another system administrator card? (y/n) " choice
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
