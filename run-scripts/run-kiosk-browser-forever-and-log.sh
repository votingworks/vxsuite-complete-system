#!/usr/bin/env bash

set -euo pipefail

# go to directory where this file is located
cd "$(dirname "$0")"

# rotate vx-logs.log if necessary
# always return true on failure since logs dont always need rotating
# but logrotate throws an error code
sudo /sbin/logrotate --force /etc/vx-logs.logrotate || true

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
    echo "starting chromium"
    ./run-kiosk-browser.sh http://localhost:3000/
done 2>&1 | logger -S 4096 --tag votingworksapp
