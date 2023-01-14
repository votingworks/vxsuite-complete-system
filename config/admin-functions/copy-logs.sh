#!/usr/bin/env bash

set -euo pipefail

echo "Let's copy the logs to a USB stick"

# check for USB stick
DEVICE=$( readlink -f $( ls /dev/disk/by-id/usb*part* 2>/dev/null ) 2>/dev/null )

# If no devices
if [ -z "$DEVICE" ]
then
    echo "no USB drives plugged in"
    exit 0
fi

# mount if needed
MOUNTPOINT=$( lsblk -n ${DEVICE} | awk '{ print $7 }' )
if [ -z "$MOUNTPOINT" ]
then
    echo "not mounted, mounting now"
    MOUNTPOINT="/media/vx/usb-drive"
    sudo /vx/ui/ui-functions/manage-usb-drive.sh --mount $DEVICE usb-drive
fi

# create a directory
DIRECTORY="$MOUNTPOINT/logs-$( date +%Y%m%d-%H%M%S )"
mkdir -p "$DIRECTORY"

# copy logs
cp -rp /var/log/syslog* "$DIRECTORY"
cp -rp /var/log/auth.log* "$DIRECTORY"
cp -rp /var/log/vx-logs.log* "$DIRECTORY"

# unmount the USB stick to make sure it's all written to disk
echo "Saving logs to USB drive..."
sync $MOUNTPOINT
sudo /vx/ui/ui-functions/manage-usb-drive.sh --unmount usb-drive

echo "All done. You may now remove the USB drive."
echo "Type Enter to continue."
read
