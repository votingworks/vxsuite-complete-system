#!/bin/bash

set -euo pipefail

usage () {
    echo 'Usage: umount.sh'
    exit 1
}

if ! [[ $# -eq 0 ]]; then
    usage
fi

MOUNTPOINT=/media/vx/usb-drive
umount $MOUNTPOINT
