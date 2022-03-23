#!/usr/bin/env bash

set -euo pipefail

: "${VX_FUNCTIONS_ROOT:="$(dirname "$0")"}"
: "${VX_CONFIG_ROOT:="/vx/config"}"

if [[ "${VX_MACHINE_ID}" != "0000" ]]; then
    echo "Current Machine ID: ${VX_MACHINE_ID}"
fi
while true; do
  read -p "Enter Machine ID (e.g. 0012): " MACHINE_ID
  if [[ "${MACHINE_ID}" =~ ^[-0-9A-Z]+$ ]]; then
    read -p "Confirm that Machine ID should be set to: ${MACHINE_ID} (y/n) " CONFIRM
    if [[ "${CONFIRM}" = "y" ]]; then
      mkdir -p "${VX_CONFIG_ROOT}"
      echo "${MACHINE_ID}" > "${VX_CONFIG_ROOT}/machine-id"
      echo "Machine ID set!"
      break
    fi
  else
    echo -e "\e[31mExpected Machine ID to be non-empty and contain only numbers, uppercase letters, and dashes, got: ${MACHINE_ID}\e[0m" >&2
  fi
done
