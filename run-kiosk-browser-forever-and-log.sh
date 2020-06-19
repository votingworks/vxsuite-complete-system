#!/usr/bin/env bash

set -euo pipefail

# go to directory where this file is located
cd "$(dirname "$0")"

# FIXME: this environment variable is never set up properly
# so this won't work for BMD
if [ "${VX_MACHINE_TYPE:-}" = bmd ]; then
    URL=http://localhost:3000/speech-loader.html
else
    URL=http://localhost:3000/
fi

while true; do
    echo "starting kiosk-browser"
    ./run-kiosk-browser.sh "$URL"
done 2>&1 | logger --tag kiosk-browser
