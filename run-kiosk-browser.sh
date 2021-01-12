#!/bin/bash

URL=$1

kiosk-browser --add-file-perm o=http://localhost:3000,p=/media/**/*,rw --autoconfigure-print-config ./printing/printer-autoconfigure.json --url ${URL:-http://localhost:3000}

