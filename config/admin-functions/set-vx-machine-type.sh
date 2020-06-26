#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx-config"}"

MACHINE_TYPE="${1:-}"

if [ -z "${MACHINE_TYPE}" ]; then
  echo "error: missing TYPE: $(basename "$0") TYPE" >&2
  exit 1
fi

echo "${MACHINE_TYPE}" > "${VX_CONFIG_ROOT}/machine-type"
