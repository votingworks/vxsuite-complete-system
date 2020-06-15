#!/usr/bin/env bash

set -euo pipefail

: "${VX_ROOT:="${HOME}"}"
: "${VX_CONFIG_ROOT:="${HOME}/.config"}"

MACHINE_TYPE="${1:-}"

if [ -z "${MACHINE_TYPE}" ]; then
  echo "error: missing TYPE: $(basename "$0") TYPE" >&2
  exit 1
fi

mkdir -p "${VX_CONFIG_ROOT}"
echo "${MACHINE_TYPE}" > "${VX_CONFIG_ROOT}/machine-type"

# Ensure VX_MACHINE_TYPE is set from the config we just wrote.
source "${VX_ROOT}/config/functions/read-vx-machine-config.sh"

# This step depends on VX_MACHINE_TYPE being set.
"${VX_ROOT}/config/functions/choose-vx-machine-id.sh"
