#!/usr/bin/env bash

set -euo pipefail
declare -A TIMEZONES
TIMEZONES["P"]="America/Los_Angeles"
TIMEZONES["M"]="America/Phoenix"
TIMEZONES["C"]="America/Chicago"
TIMEZONES["E"]="America/New_York"

echo "Let's set the system date, time, and timezone!"
while true; do
    read -p "Date (e.g. 2020-05-09): " DATE
    if date -d "${DATE}" > /dev/null  2>&1
    then
	break
    fi
done

while true; do
    read -p "Time in 24h style (e.g. 19:): " TIME
    if date -d "${TIME}" > /dev/null  2>&1
    then
	break
    fi
done

while true; do
    read -p "Timezone - (P)acific, (M)ountain, (C)entral, (E)astern: " TZ
    if [[ "${TZ}" =~ ^[P,M,C,E]$ ]]; then
	break
    fi
done

sudo timedatectl set-time "${DATE} ${TIME} ${TIMEZONES[${TZ}]}"
sudo timedatectl set-timezone "${TIMEZONES[${TZ}]}"

echo "Done!"
