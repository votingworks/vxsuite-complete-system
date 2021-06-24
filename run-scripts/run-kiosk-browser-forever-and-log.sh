#!/usr/bin/env bash

set -euo pipefail

# go to directory where this file is located
cd "$(dirname "$0")"

# configuration information
CONFIG=${VX_CONFIG_ROOT:-./config}
source ${CONFIG}/read-vx-machine-config.sh

: "${VX_MACHINE_TYPE:=""}"

# remove pointer on screen
if [ "${VX_MACHINE_TYPE}" = "bmd" ] || [ "${VX_MACHINE_TYPE}" = "bas" ] || [ "${VX_MACHINE_TYPE}" = "precinct-scanner" ]; then
    unclutter -idle 0.01 -root &
fi
    

if [ "${VX_MACHINE_TYPE}" = "bmd" ]; then
    amixer -D pulse set Master 80% || true
    
    URL=http://localhost:3000/speech-loader.html
else
    URL=http://localhost:3000/
fi

while true; do
    echo "starting kiosk-browser"
    ./run-kiosk-browser.sh "$URL"
done 2>&1 | logger --tag kiosk-browser
