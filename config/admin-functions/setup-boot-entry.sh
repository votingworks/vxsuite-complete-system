#!/usr/bin/env bash

set -euo pipefail

# detect Surface Go
if dmidecode | grep -q 'Surface Go'; then
    surface=1
else
    surface=0
fi

EFIDIR="/boot/efi/EFI/debian"
TARGET="VxLinux-signed.efi"
OUTDIR="${EFIDIR}/${TARGET}"
DEV="$(df "$OUTDIR" | tail -1 | cut -d' ' -f1)"
part=$(cat /sys/class/block/$(basename $DEV)/partition)

if [ $surface == 0 ]; then
    efibootmgr \
        --create \
        --disk "$DEV" \
        --part $part \
        --label "VxLinux" \
        --loader "\\EFI\\debian\\VxLinux-signed.efi" \
        --quiet
fi
