#!/usr/bin/env bash

# go to directory where this file is located
cd "$(dirname "$0")"

: "${VX_CONFIG_ROOT:="./config"}"
: "${VX_DATA_ROOT:="${HOME}/data"}"

# configuration information
source ${VX_CONFIG_ROOT}/read-vx-machine-config.sh

export MODULE_SCAN_WORKSPACE="${VX_DATA_ROOT}/module-scan-workspace"
mkdir -p "${MODULE_SCAN_WORKSPACE}"

export PIPENV_VENV_IN_PROJECT=1
(trap 'kill 0' SIGINT SIGHUP; make -C vxsuite/apps/module-scan run & make -C vxsuite/apps/bsd run)
