#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"

while true; do
  read -p "${VX_MACHINE_TYPE} Machine ID (e.g. 0012): " MACHINE_ID
  if [[ "${MACHINE_ID}" =~ ^[0-9]+$ ]]; then
    mkdir -p "${VX_CONFIG_ROOT}"
    sudo hostnamectl set-hostname "vx-${VX_MACHINE_TYPE}-${MACHINE_ID}"
    echo "${MACHINE_ID}" > "${VX_CONFIG_ROOT}/machine-id"
    break
  else
    echo -e "\e[31mExpected Machine ID to be non-empty and only numbers, got: ${MACHINE_ID}\e[0m" >&2
  fi
done
