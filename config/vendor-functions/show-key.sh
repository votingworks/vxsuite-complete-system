#!/usr/bin/env bash

trap '' SIGINT SIGTSTP SIGQUIT

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"

cat "${VX_CONFIG_ROOT}/key.pub" | qrencode -t ANSI -o -
