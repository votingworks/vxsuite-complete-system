#!/usr/bin/env bash

set -euo pipefail

# go to directory where this file is located
cd "$(dirname "$0")"

: "${VX_CONFIG_ROOT:="./config"}"

# configuration information
source ${VX_CONFIG_ROOT}/read-vx-machine-config.sh

export PIPENV_VENV_IN_PROJECT=1
(trap 'kill 0' SIGINT SIGHUP; make -C components/module-converter-sems run & make -C frontends/election-manager run)
