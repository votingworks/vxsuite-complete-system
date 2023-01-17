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
umount $MOUNTPOINT
