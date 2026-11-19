#!/usr/bin/env bash

trap '' SIGINT SIGTSTP SIGQUIT

set -euo pipefail

# go to directory where this file is located
cd "$(dirname "$0")"

# Rotate vx-logs.log. A failure here mustn't stop the kiosk from starting, so
# ignore it. -n makes sudo fail rather than prompt for a password, which would
# stop this background script before it starts the kiosk.
sudo -n /vx/code/config/vendor-functions/rotate-logs.sh || true

# configuration information
CONFIG=${VX_CONFIG_ROOT:-./config}
METADATA=${VX_METADATA_ROOT:-./}
source ${CONFIG}/read-vx-machine-config.sh

: "${VX_MACHINE_TYPE:=""}"

# remove pointer on screen
if [ "${VX_MACHINE_TYPE}" = "mark" ] || [ "${VX_MACHINE_TYPE}" = "mark-scan" ]|| [ "${VX_MACHINE_TYPE}" = "scan" ]; then
    unclutter -idle 0.01 -root &
fi
    

if [ "${VX_MACHINE_TYPE}" = "mark" ]; then
    amixer -D pulse set Master 80% || true
fi

# Max out volume for sound effects
if [ "${VX_MACHINE_TYPE}" = "scan" ]; then
    amixer -D pulse set Master 100% || true
fi

while true; do
    echo "starting kiosk-browser"
    ./run-kiosk-browser.sh http://localhost:3000/
done 2>&1 | logger -S 4096 --tag votingworksapp
