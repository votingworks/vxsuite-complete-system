#!/usr/bin/env bash

set -euo pipefail

# load configuration
source /vx-config/read-vx-machine-config.sh

# go to directory where this file is located
cd "$(dirname "$0")"

: "${VX_MACHINE_TYPE:=""}"

# remove pointer on screen
if [ "${VX_MACHINE_TYPE}" = "bmd" ] || [ "${VX_MACHINE_TYPE}" = "bas" ]; then
    unclutter -idle 0.01 -root &
fi
    

if [ "${VX_MACHINE_TYPE}" = "bmd" ]; then
    amixer set Master 75%
    URL=http://localhost:3000/speech-loader.html
else
    URL=http://localhost:3000/
fi

while true; do
    echo "starting kiosk-browser"
    ./run-kiosk-browser.sh "$URL"
done 2>&1 | logger --tag kiosk-browser
