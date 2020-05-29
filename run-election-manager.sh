#!/usr/bin/env bash

export PIPENV_VENV_IN_PROJECT=1
(trap 'kill 0' SIGINT SIGHUP; make -C components/module-usbstick run & make -C components/module-smartcards run & make -C components/module-sems-converter run & make -C frontends/election-manager run)
