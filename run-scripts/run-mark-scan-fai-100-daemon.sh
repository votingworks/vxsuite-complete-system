#!/usr/bin/env bash

set -euo pipefail

# go to directory where this file is located
cd "$(dirname "$0")"

# configuration information
CONFIG=${VX_CONFIG_ROOT:-./config}
METADATA=${VX_METADATA_ROOT:-./}
source ${CONFIG}/read-vx-machine-config.sh

(trap 'kill 0' SIGINT SIGHUP; make -C vxsuite/apps/mark-scan/fai-100-controller run) | logger -S 4096 --tag votingworksapp
