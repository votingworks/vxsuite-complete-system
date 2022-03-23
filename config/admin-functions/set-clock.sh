#!/usr/bin/env bash

set -euo pipefail
declare -A TIMEZONES
TIMEZONES["p"]="America/Los_Angeles"
TIMEZONES["m"]="America/Phoenix"
TIMEZONES["c"]="America/Chicago"
TIMEZONES["e"]="America/New_York"

echo "System clock is currently set to: $(date)"

echo "Let's set the date"
while true; do
    while true; do
        read -p "Enter the month (e.g. 3): " MONTH
        [[ "${MONTH}" =~ ^0?[1-9]|11|12$ ]] && break
        echo -e "\e[31mInvalid month, try again\e[0m" >&2
    done

    while true; do
        read -p "Enter the day (e.g. 7): " DAY
        [[ "${DAY}" =~ ^[0-3]?[0-9]$ ]] && break
        echo -e "\e[31mInvalid day, try again\e[0m" >&2
    done

    while true; do
        read -p "Enter the year (e.g. 2020): " YEAR
        [[ "${YEAR}" =~ ^[0-9]{4}$ ]] && break
        echo -e "\e[31mInvalid year, try again\e[0m" >&2
    done
    
    DATE="${MONTH}/${DAY}/${YEAR}"
    if date -d "${DATE}" > /dev/null 2>&1; then
        read -p "Confirm that date should be set to ${DATE}? (y/n) " CONFIRM
        [[ "${CONFIRM}" = "y" ]] && break
    else
        echo -e "\e[31mInvalid year/month/day combination, try again\e[0m" >&2
    fi
done

echo "Let's set the time"
while true; do
    while true; do
        read -p "Pick a timezone - (p)acific, (m)ountain, (c)entral, (e)astern: " TZ
        [[ "${TZ}" =~ ^p|m|c|e$ ]] && break
        echo -e "\e[31mInvalid timezone, try again\e[0m" >&2
    done

    while true; do
        read -p "Enter the time (e.g. 12:15pm): " TIME
        date -d "${TIME}" > /dev/null  2>&1 && break
        echo -e "\e[31mInvalid time, try again\e[0m" >&2
    done

    read -p "Confirm that the time should be set to ${TIME}? (y/n) " CONFIRM
    [[ "${CONFIRM}" = "y" ]] && break
done

timedatectl set-timezone "${TIMEZONES[${TZ}]}"
timedatectl set-time "$(date -d "${DATE} ${TIME}" +"%F %T")"

echo "Clock is now set to: $(date)"
