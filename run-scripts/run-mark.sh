#!/usr/bin/env bash

trap '' SIGINT SIGTSTP SIGQUIT
set -euo pipefail

# go to directory where this file is located
cd "$(dirname "$0")"

# configuration information
CONFIG=${VX_CONFIG_ROOT:-./config}
METADATA=${VX_METADATA_ROOT:-./}
source ${CONFIG}/read-vx-machine-config.sh

export NODE_ENV=production
export PIPENV_VENV_IN_PROJECT=1
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
(trap 'kill 0' SIGINT SIGHUP; make -C vxsuite/apps/mark/backend run & make -C vxsuite/apps/mark/frontend run) | logger -S 4096 --tag votingworksapp
