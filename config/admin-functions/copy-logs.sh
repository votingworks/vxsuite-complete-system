#!/usr/bin/env bash

set -euo pipefail

echo "Let's copy the logs to a USB stick."

# check for USB stick
DEVICES=$( readlink -f $( ls /dev/disk/by-id/usb*part* 2>/dev/null ) 2>/dev/null )

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
DIRECTORY="$MOUNTPOINT/logs-$( date +%Y%m%d-%H%M%S )"
mkdir -p "$DIRECTORY"

# copy logs
cp -r /var/log/votingworks/syslog* "$DIRECTORY"
cp -r /var/log/votingworks/auth.log* "$DIRECTORY"
cp -r /var/log/votingworks/vx-logs.log* "$DIRECTORY"

# unmount the USB stick to make sure it's all written to disk
echo "Saving logs to USB drive..."
sync $MOUNTPOINT
sudo /vx/code/app-scripts/unmount-usb.sh

echo "All done. You may remove the USB drive."
echo "Type Enter to continue."
read
