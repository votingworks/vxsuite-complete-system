#!/usr/bin/env bash

set -euo pipefail

echo "Let's copy the screen recordings to a USB stick."

# check for USB stick
DEVICES=$( readlink -f $( ls /dev/disk/by-id/usb*part* 2>/dev/null || echo "") 2>/dev/null || echo "")

# If no devices
if [ -z "$DEVICES" ]
then
    echo "No USB drives plugged in."
    exit 0
fi

# mount if needed
MOUNTPOINT=$( lsblk -n ${DEVICES} | awk '{ print $7 }' )
if [ -z "$MOUNTPOINT" ]
then
    echo "USB drive not mounted, mounting now..."
    MOUNTPOINT="/media/vx/usb-drive"
    sudo /vx/code/app-scripts/mount-usb.sh $DEVICES
fi

# create a directory
DIRECTORY="$MOUNTPOINT/screen-recordings"
mkdir -p "$DIRECTORY"

# copy recordings
sudo sh -c "cp /var/vx/ui/screen-recordings/*.mp4 $DIRECTORY"

# unmount the USB stick to make sure it's all written to disk
echo "Saving to USB drive and unmounting..."
sync $MOUNTPOINT
sudo /vx/code/app-scripts/unmount-usb.sh

echo "All done. You may remove the USB drive."
echo "Type Enter to continue."
read
