#!/bin/bash

set -euo pipefail

URL=${1:-http://localhost:3000}
: "${VX_CONFIG_ROOT:="./config"}"


kiosk-browser --add-file-perm o=http://localhost:3000,p=/media/**/*,rw --autoconfigure-print-config ./printing/printer-autoconfigure.json --url ${URL} --signify-secret-key ${VX_CONFIG_ROOT}/key.sec

