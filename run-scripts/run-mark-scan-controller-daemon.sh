#!/usr/bin/env bash

set -euo pipefail

# go to directory where this file is located
cd "$(dirname "$0")"

# configuration information
CONFIG=${VX_CONFIG_ROOT:-./config}
# shellcheck disable=SC2034
METADATA=${VX_METADATA_ROOT:-./}
# shellcheck source=config/read-vx-machine-config.sh
source "${CONFIG}"/read-vx-machine-config.sh

(trap 'kill 0' SIGINT SIGHUP; make -C vxsuite/apps/mark-scan/accessible-controller run) | logger -S 4096 --tag votingworksapp
