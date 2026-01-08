#!/usr/bin/env bash

set -euo pipefail

# go to directory where this file is located
cd "$(dirname "$0")"

# configuration information
CONFIG=${VX_CONFIG_ROOT:-./config}
METADATA=${VX_METADATA_ROOT:-./}
# shellcheck source=config/read-vx-machine-config.sh
source "${CONFIG}"/read-vx-machine-config.sh

if [ -z "${PRINT_WORKSPACE:-}" ]; then
  echo "error: please set PRINT_WORKSPACE and try again" >&2
  exit 1
fi

export PIPENV_VENV_IN_PROJECT=1
export NODE_ENV=production
(trap 'kill 0' SIGINT SIGHUP; make -C vxsuite/apps/print/backend run & make -C vxsuite/apps/print/frontend run) | logger -S 4096 --tag votingworksapp
