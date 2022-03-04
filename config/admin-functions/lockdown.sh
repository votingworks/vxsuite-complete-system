#!/bin/bash
set -euo pipefail 

update-initramfs -u

# Remount / so it can't change while we're doing the veritysetup
mount -o ro,remount /

# Now do the dm-verity setup
veritysetup format /dev/mapper/Vx--vg-root /dev/mapper/Vx--vg-hashes| tee "/tmp/verity.log"

# Find the root hash and append it to our cmdline
HASH="$(awk '/Root hash:/ { print $3 }' "/tmp/verity.log")"
echo "$(cat /vx/admin/config/cmdline)${HASH}" > /tmp/cmdline

# TODO: Make sure the output initramfs/kernel file names are correct!
# Now package up our kernel, cmdline, etc
objcopy \
    --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \
    --add-section .cmdline="/tmp/cmdline" --change-section-vma .cmdline=0x30000 \
    --add-section .splash="/vx/admin/config/logo.bmp" --change-section-vma .splash=0x40000 \
    --add-section .linux="/boot/vmlinuz-5.10.0-11-amd64" --change-section-vma .linux=0x2000000 \
    --add-section .initrd="/boot/initrd.img-5.10.0-11-amd64" --change-section-vma .initrd=0x3000000 \
    "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" "/tmp/linux.efi"

# Sign the resulting binary
# First make sure the drive is mounted
mount /dev/sda /mnt

sbsign --key=/mnt/DB.key --cert=/mnt/DB.crt --output /boot/efi/EFI/debian/VxLinux-signed.efi /tmp/linux.efi

# Now install it 
bash setup-boot-entry.sh

# Reboot into the locked down system
echo "Rebooting in 5s"
sleep 5
systemctl reboot -i
