#!/bin/bash

set -euo pipefail

URL=${1:-http://localhost:3000}
: "${VX_CONFIG_ROOT:="./config"}"
: "${VX_METADATA_ROOT:="./"}"

OS=$(lsb_release -cs)
PRINTER_FILE='./printing/printer-autoconfigure.json'
if [[ $OS == "bullseye" ]]; then
	PRINTER_FILE='./printing/debian-printer-autoconfigure.json'
fi

kiosk-browser \
  --add-file-perm o=http://localhost:3000,p=/media/**/*,rw \
  --add-file-perm o=http://localhost:3000,p=/var/log,ro \
  --add-file-perm o=http://localhost:3000,p=/var/log/*,ro \
  --autoconfigure-print-config ${PRINTER_FILE} \
  --app-scripts-directory ./app-scripts \
  --url ${URL} || true

