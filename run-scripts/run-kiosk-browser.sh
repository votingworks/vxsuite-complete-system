#!/bin/bash

trap '' SIGINT SIGTSTP SIGQUIT

set -euo pipefail

URL=${1:-http://localhost:3000}
: "${VX_CONFIG_ROOT:="./config"}"
: "${VX_METADATA_ROOT:="./"}"

OS=$(lsb_release -cs)

# Let the vxdev dev dock take screenshots and recordings of the page.
ENV_FILE=/vx/config/.env.local
if [ -f "${ENV_FILE}" ] \
    && grep -qix 'REACT_APP_VX_DEV=true' "${ENV_FILE}" \
    && grep -qix 'REACT_APP_VX_ENABLE_DEV_DOCK=true' "${ENV_FILE}"; then
  export KIOSK_BROWSER_ALLOW_DEVTOOLS=true
fi

kiosk-browser --url ${URL} || true

