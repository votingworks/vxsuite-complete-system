#!/bin/bash

set -euo pipefail

usage () {
    echo 'Usage:'
    echo ' manage-usb-drive.sh --mount <device> <label>'
    echo ' manage-usb-drive.sh --unmount <label>'
    exit 1
}

DEVICE_REGEX=^/dev/sd[a-z][0-9]$
LABEL_REGEX=^[a-zA-Z0-9\-]*$


if [[ $# -lt 1 ]]; then
    usage
fi

if [[ $1 = '--unmount' ]]; then
    if [[ $# -lt 2 ]]; then
        usage
    fi

    if [[ ! $2 =~ $LABEL_REGEX ]]; then
        echo "manage-usb-drive.sh: label \"${2}\" is not valid"
        exit 1
    fi

    MOUNTPOINT=/media/vx/$2

    if [[ ! -e $MOUNTPOINT ]]; then
        echo "manage-usb-drive.sh: no device mounted with that label"
        exit 1
    fi

    umount $MOUNTPOINT
    rm -r $MOUNTPOINT
elif [[ $1 = '--mount' ]]; then
    if [[ $# -lt 3 ]]; then
        usage
    fi
    
    if [[ ! $2 =~ $DEVICE_REGEX ]]; then
        echo "manage-usb-drive.sh: device \"${2}\" is not a USB drive"
        exit 1
    fi

    DEVICE=$2

    if [[ ! $3 =~ $LABEL_REGEX ]]; then
        echo "manage-usb-drive.sh: label \"${3}\" is not valid"
        echo "Only alphanumeric characters and dashes are allowed in labels."
        exit 1
    fi

    MOUNTPOINT=/media/vx/$3

    mkdir -p $MOUNTPOINT
    mount -w -o umask=000,nosuid,nodev,noexec $DEVICE $MOUNTPOINT
else
    usage
fi
