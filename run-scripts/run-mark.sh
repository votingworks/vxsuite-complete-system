#!/usr/bin/env bash

set -euo pipefail

# go to directory where this file is located
cd "$(dirname "$0")"

# configuration information
CONFIG=${VX_CONFIG_ROOT:-./config}
METADATA=${VX_METADATA_ROOT:-./}
source ${CONFIG}/read-vx-machine-config.sh

export PIPENV_VENV_IN_PROJECT=1
export NODE_ENV=production
(trap 'kill 0' SIGINT SIGHUP; make -C vxsuite/apps/mark/backend run & make -C vxsuite/apps/mark/frontend run) | logger --tag votingworksapp
