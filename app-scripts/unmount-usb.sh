#!/bin/bash

set -euo pipefail

usage () {
    echo 'Usage: unmount-usb.sh'
    exit 1
}

if ! [[ $# -eq 0 ]]; then
    usage
fi

MOUNTPOINT=/media/vx/usb-drive

# Pull out all the stops to make sure that data is flushed.
#
# The app is now auto-mounting USB drives at device-specific paths, e.g.,
# /media/vx/usb-drive-sdb1. Vendor functions haven't been migrated to that
# system yet and still perform their own mounting at /media/vx/usb-drive. This
# means that, in the context of vendor functions like the cert dance, USB
# drives can be double mounted. While an unmount will typically flush data,
# it may not do so when a drive is still mounted at some other location. We
# accordingly explicitly flush.
#
sync # Flush across all locations rather than using sync -f $MOUNTPOINT
umount $MOUNTPOINT
sleep 2 # Shouldn't be necessary but throwing it in for good measure
