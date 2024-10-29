#!/usr/bin/env bash

set -euo pipefail

EFIDIR="/boot/efi/EFI/debian"
TARGET="VxLinux-signed.efi"
OUTDIR="${EFIDIR}/${TARGET}"
DEV="$(df "$OUTDIR" | tail -1 | cut -d' ' -f1)"
part=$(cat /sys/class/block/$(basename $DEV)/partition)
efibootmgr \
    --create \
    --disk "$DEV" \
    --part $part \
    --label "VxLinux" \
    --loader "\\EFI\\debian\\VxLinux-signed.efi" \
    --quiet
