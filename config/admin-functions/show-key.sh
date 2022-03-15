#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"

cat "${VX_CONFIG_ROOT}/key.pub" | qrencode -t ANSIUTF8 -o -