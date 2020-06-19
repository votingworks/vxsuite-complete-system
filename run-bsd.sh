#!/usr/bin/env bash

# go to directory where this file is located
cd "$(dirname "$0")"

export PIPENV_VENV_IN_PROJECT=1
(trap 'kill 0' SIGINT SIGHUP; make -C components/module-scan run & make -C frontends/bsd run)
