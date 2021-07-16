#!/usr/bin/env bash

set -euo pipefail

# go to directory where this file is located
cd "$(dirname "$0")"

# configuration information
CONFIG=${VX_CONFIG_ROOT:-./config}
source ${CONFIG}/read-vx-machine-config.sh

if [ -z "${MODULE_SCAN_WORKSPACE:-}" ]; then
  echo "error: please set MODULE_SCAN_WORKSPACE and try again" >&2
  exit 1
fi

export PIPENV_VENV_IN_PROJECT=1
export NODE_ENV=production
(trap 'kill 0' SIGINT SIGHUP; make -C vxsuite/apps/module-scan run & make -C vxsuite/apps/module-smartcards run & make -C vxsuite/apps/precinct-scanner run)
