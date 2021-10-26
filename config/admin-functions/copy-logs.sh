#!/usr/bin/env bash

set -euo pipefail

echo "Let's copy the logs to a USB stick"

# check for USB stick
DEVICES=$( readlink -f $( ls /dev/disk/by-id/usb*part* 2>/dev/null ) 2>/dev/null )

# If no devices
if [ -z "$DEVICES" ]
then
    echo "no USB drives plugged in"
    exit 0
fi

# mount if needed
MOUNTPOINT=$( lsblk -n ${DEVICES} | awk '{ print $7 }' )
SHORT_DEVICE=$( echo "$DEVICES" | sed 's/\/dev\///' )
if [ -z "$MOUNTPOINT" ]
then
    echo "not mounted, mounting now"
    MOUNTPOINT="/media/usb-drive-${SHORT_DEVICE}"
    pmount -w -u 000 "$DEVICES" "$MOUNTPOINT"
fi

# create a directory
DIRECTORY="$MOUNTPOINT/logs-$( date +%Y%m%d-%H%M%S )"
mkdir -p "$DIRECTORY"

# copy logs
cp -rp /var/log/syslog* "$DIRECTORY"
cp -rp /var/log/auth.log* "$DIRECTORY"
cp -rp /var/log/vx-logs.log* "$DIRECTORY"

# unmount the USB stick to make sure it's all written to disk
pumount "$DEVICES"

echo "All done. Please wait a few seconds before removing USB drive."
echo "Type Enter to continue."
read
