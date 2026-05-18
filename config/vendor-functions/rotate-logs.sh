#!/usr/bin/env bash

trap '' SIGINT SIGTSTP SIGQUIT

set -euo pipefail

/sbin/logrotate --force /etc/vx-logs.logrotate
