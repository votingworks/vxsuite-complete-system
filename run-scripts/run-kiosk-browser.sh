#!/bin/bash

set -euo pipefail

URL=${1:-http://localhost:3000}
PRINTER_FILE='./printing/debian-printer-autoconfigure.json'

case "${VX_MACHINE_TYPE:-}" in
  scan|admin|central-scan)
    # for these apps, kiosk browser does not need to or should not configure printers
    kiosk-browser \
      --add-file-perm o=http://localhost:3000,p=/media/**/*,rw \
      --add-file-perm o=http://localhost:3000,p=/var/log,ro \
      --add-file-perm o=http://localhost:3000,p=/var/log/*,ro \
      --url ${URL} || true
    ;;
  *)
    # by default, for mark and development, kiosk browser handles configuring printers
    kiosk-browser \
      --add-file-perm o=http://localhost:3000,p=/media/**/*,rw \
      --add-file-perm o=http://localhost:3000,p=/var/log,ro \
      --add-file-perm o=http://localhost:3000,p=/var/log/*,ro \
      --autoconfigure-print-config ${PRINTER_FILE} \
      --url ${URL} || true
    ;;
esac