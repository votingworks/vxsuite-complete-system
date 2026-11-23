#!/usr/bin/env bash

trap '' SIGINT SIGTSTP SIGQUIT

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"

STATE_CODES=('DEMO' 'MI' 'MS' 'NH')

CURRENT_STATE=$(cat "${VX_CONFIG_ROOT}/machine-state" 2>/dev/null || true)
MACHINE_JURISDICTION=$(cat "${VX_CONFIG_ROOT}/machine-jurisdiction" 2>/dev/null || true)
JURISDICTION_STATE=$(echo "${MACHINE_JURISDICTION%%.*}" | tr '[:lower:]' '[:upper:]')
if [[ "${JURISDICTION_STATE}" = "VX" ]]; then
  JURISDICTION_STATE="DEMO"
fi

DEFAULT_STATE=""
for STATE_CODE in "${STATE_CODES[@]}"; do
  if [[ "${STATE_CODE}" = "${CURRENT_STATE}" ]]; then
    DEFAULT_STATE="${STATE_CODE}"
    break
  fi
  if [[ "${STATE_CODE}" = "${JURISDICTION_STATE}" ]]; then
    DEFAULT_STATE="${STATE_CODE}"
  fi
done

if [[ -n "${CURRENT_STATE}" ]]; then
  echo "Current Machine State: ${CURRENT_STATE}"
fi
for i in "${!STATE_CODES[@]}"; do
  echo "$((i + 1)). ${STATE_CODES[$i]}"
done

while true; do
  if [[ -n "${DEFAULT_STATE}" ]]; then
    read -p "Select Machine State (press enter for ${DEFAULT_STATE}): " CHOICE
  else
    read -p "Select Machine State: " CHOICE
  fi

  if [[ -z "${CHOICE}" && -n "${DEFAULT_STATE}" ]]; then
    MACHINE_STATE="${DEFAULT_STATE}"
  elif [[ "${CHOICE}" =~ ^[0-9]{1,2}$ ]] && (( CHOICE >= 1 && CHOICE <= ${#STATE_CODES[@]} )); then
    MACHINE_STATE="${STATE_CODES[$((CHOICE - 1))]}"
  else
    echo -e "\e[31mExpected a number from 1 to ${#STATE_CODES[@]}, got: ${CHOICE}\e[0m" >&2
    continue
  fi

  read -p "Confirm that Machine State should be set to: ${MACHINE_STATE} (y/n) " CONFIRM
  if [[ "${CONFIRM}" = "y" ]]; then
    mkdir -p "${VX_CONFIG_ROOT}"
    echo "${MACHINE_STATE}" > "${VX_CONFIG_ROOT}/machine-state"
    echo "Machine State set!"
    break
  fi
done
