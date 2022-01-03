#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"

while true; do
  read -p "${VX_MACHINE_TYPE} Machine Model Name (e.g. VxScan 1.0): " MACHINE_MODEL_NAME
  if [[ "${MACHINE_MODEL_NAME}" =~ ^[-.[:space:]0-9A-Za-z]+$ ]]; then
    mkdir -p "${VX_CONFIG_ROOT}"
    echo "${MACHINE_MODEL_NAME}" > "${VX_CONFIG_ROOT}/machine-model-name"
    break
  else
    echo -e "\e[31mExpected Machine Model Name to be non-empty and contain only numbers, uppercase letters, spaces, and dashes, got: ${MACHINE_MODEL_NAME}\e[0m" >&2
  fi
done
