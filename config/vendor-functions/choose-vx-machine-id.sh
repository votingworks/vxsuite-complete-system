#!/usr/bin/env bash

set -euo pipefail

: "${VX_FUNCTIONS_ROOT:="$(dirname "$0")"}"
: "${VX_CONFIG_ROOT:="/vx/config"}"

# since root does not source the vx machine config
# we get the machine-id directly
VX_MACHINE_ID=$(cat "${VX_CONFIG_ROOT}"/machine-id 2>/dev/null)
if [[ "${VX_MACHINE_ID}" != "0000" ]]; then
    echo "Current Machine ID: ${VX_MACHINE_ID}"
fi
while true; do
  read -r -p "Enter Machine ID (e.g. 0012): " MACHINE_ID
  if [[ "${MACHINE_ID}" =~ ^[-0-9A-Z]+$ ]]; then
    read -r -p "Confirm that Machine ID should be set to: ${MACHINE_ID} (y/n) " CONFIRM
    if [[ "${CONFIRM}" = "y" ]]; then
      mkdir -p "${VX_CONFIG_ROOT}"
      echo "${MACHINE_ID}" > "${VX_CONFIG_ROOT}/machine-id"

      # If this is a poll-book machine, we update the /etc/hosts file
      # and set the hostname
      if [[ $(cat "${VX_CONFIG_ROOT}"/machine-type 2>/dev/null) == "poll-book" ]]; then
        sed "/^127\.0\.1\.1/ s/.*/127.0.1.1\tVx${MACHINE_ID}/" /etc/hosts > /var/tmp/hosts
        cp /var/tmp/hosts /etc/hosts
        #hostnamectl set-hostname "Vx${MACHINE_ID}" 2>/dev/null
        echo "Vx${MACHINE_ID}" > /etc/hostname
        hostname -F /etc/hostname
      fi

      echo "Machine ID set!"
      break
    fi
  else
    echo -e "\e[31mExpected Machine ID to be non-empty and contain only numbers, uppercase letters, and dashes, got: ${MACHINE_ID}\e[0m" >&2
  fi
done
