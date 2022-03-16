#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"

rm -f "${VX_CONFIG_ROOT}/key.pub" "${VX_CONFIG_ROOT}/key.sec"
signify-openbsd -G -n -p "${VX_CONFIG_ROOT}/key.pub" -s "${VX_CONFIG_ROOT}/key.sec"
# Make the signing key readable by vx-group
# We may want to further limit this in the future
chgrp vx-group "${VX_CONFIG_ROOT}/key.sec"
chmod g+r "${VX_CONFIG_ROOT}/key.sec"
cat "${VX_CONFIG_ROOT}/key.pub" | qrencode -t ANSI -o -