#!/usr/bin/env bash

trap '' SIGINT SIGTSTP SIGQUIT

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"

CURRENT_STATE=$(cat "${VX_CONFIG_ROOT}/machine-state" 2>/dev/null || true)
MACHINE_JURISDICTION=$(cat "${VX_CONFIG_ROOT}/machine-jurisdiction" 2>/dev/null || true)
DEFAULT_STATE=$(echo "${MACHINE_JURISDICTION%%.*}" | tr '[:lower:]' '[:upper:]')
if [[ -z "${DEFAULT_STATE}" || "${DEFAULT_STATE}" = "VX" ]]; then
  DEFAULT_STATE="DEMO"
fi

if [[ -n "${CURRENT_STATE}" ]]; then
  echo "Current Machine State: ${CURRENT_STATE}"
fi

while true; do
  read -p "Enter Machine State (e.g. MI, or DEMO for test/demo machines; press enter for ${DEFAULT_STATE}): " MACHINE_STATE
  MACHINE_STATE=$(echo "${MACHINE_STATE:-${DEFAULT_STATE}}" | tr '[:lower:]' '[:upper:]')
  if [[ "${MACHINE_STATE}" =~ ^[A-Z]+$ ]]; then
    read -p "Confirm that Machine State should be set to: ${MACHINE_STATE} (y/n) " CONFIRM
    if [[ "${CONFIRM}" = "y" ]]; then
      mkdir -p "${VX_CONFIG_ROOT}"
      echo "${MACHINE_STATE}" > "${VX_CONFIG_ROOT}/machine-state"
      echo "Machine State set!"
      break
    fi
  else
    echo -e "\e[31mExpected Machine State to contain only letters, got: ${MACHINE_STATE}\e[0m" >&2
  fi
done
