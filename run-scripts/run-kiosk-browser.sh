#!/bin/bash

set -euo pipefail

URL=${1:-http://localhost:3000}
: "${VX_CONFIG_ROOT:="./config"}"
: "${VX_METADATA_ROOT:="./"}"

OS=$(lsb_release -cs)

kiosk-browser --url ${URL} || true

