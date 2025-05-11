#!/bin/bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="./config"}"
: "${VX_METADATA_ROOT:="./"}"

OS=$(lsb_release -cs)

bash ../vxsuite/libs/ui/scripts/run-kiosk.sh

