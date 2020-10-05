#!/bin/bash

URL=$1

kiosk-browser --allowed-save-as-hostname-pattern localhost --allowed-save-as-destination-pattern "/media/**/*" --autoconfigure-print-config ./printing/printer-autoconfigure.json --url ${URL:-http://localhost:3000}

