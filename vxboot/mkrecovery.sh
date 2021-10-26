#!/bin/bash

if [ "$EUID" -ne 0 ]; then
	echo "This script must run as root"
	exit 1
fi

TMP="$(mktemp -d)"

echo "Creating unified recovery image"
objcopy \
    --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \
    --add-section .cmdline="/home/vxadmin/recovery_cmdline" --change-section-vma .cmdline=0x30000 \
    --add-section .splash="/home/vxadmin/votingworks.png" --change-section-vma .splash=0x40000 \
    --add-section .linux="/boot/vmlinuz" --change-section-vma .linux=0x2000000 \
    --add-section .initrd="/boot/initrd.img" --change-section-vma .initrd=0x3000000 \
    "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" "${TMP}/linux.efi"

echo "Signing unified recovery image"
mkdir -p /boot/efi/EFI/recovery
sbsign --key "signing.key" --cert "cert.pem" --output "/boot/efi/EFI/recovery/linux-signed.efi" $TMP/linux.efi

echo "Updating boot manager with new image"
# remove old recovery
efibootmgr --quiet -B -b 4

efibootmgr --create --disk "/dev/nvme0n1p1" --part "1" --label "recovery" --loader "\\EFI\\recovery\\linux-signed.efi"
