#!/usr/bin/env bash

# go to directory where this file is located
cd "$(dirname "$0")"

# configuration information
source config/admin-functions/read-vx-machine-config.sh

export PIPENV_VENV_IN_PROJECT=1
(trap 'kill 0' SIGINT SIGHUP; make -C components/module-converter-sems run & make -C frontends/election-manager run)
