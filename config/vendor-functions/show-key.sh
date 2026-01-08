#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"

qrencode -t ANSI -o - <"${VX_CONFIG_ROOT}/key.pub"

