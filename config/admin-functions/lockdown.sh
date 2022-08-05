#!/bin/bash
set -euo pipefail 

: "${VX_FUNCTIONS_ROOT:="$(dirname "$0")"}"
: "${VX_CONFIG_ROOT:="/vx/config"}"

# detect Surface Go
#if dmidecode | grep -q 'Surface Go'; then
if [[ $(cat "${VX_CONFIG_ROOT}/machine-type") == "precinct-scanner" ]]; then
    surface=1
    echo "Detected a Precinct Scanner (Surface Go) device. Locking down with GRUB."
else
    surface=0
    echo "Locking down with a unified kernel binary."
fi

echo "continue? [Y/n]:" 

read -r answer

if [[ $answer != 'n' && $answer != 'N' ]]; then
    echo "Not locking down. Exiting..."
    sleep 3
    exit
fi


update-initramfs -u

# Remount / so it can't change while we're doing the veritysetup
mount -o ro,remount /

# Now do the dm-verity setup
veritysetup format /dev/mapper/Vx--vg-root /dev/mapper/Vx--vg-hashes| tee "/tmp/verity.log"

# Find the root hash and append it to our cmdline
HASH="$(awk '/Root hash:/ { print $3 }' "/tmp/verity.log")"
echo "$(cat /vx/admin/config/cmdline)${HASH}" > /tmp/cmdline

KERNEL_VERSION=`uname -r`


# Now package up our kernel, cmdline, etc, if we're not on a Surface
if [ $surface == 0 ]; then
    objcopy \
        --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \
        --add-section .cmdline="/tmp/cmdline" --change-section-vma .cmdline=0x30000 \
        --add-section .splash="/vx/admin/config/logo.bmp" --change-section-vma .splash=0x40000 \
        --add-section .linux="/boot/vmlinuz-${KERNEL_VERSION}" --change-section-vma .linux=0x2000000 \
        --add-section .initrd="/boot/initrd.img-${KERNEL_VERSION}" --change-section-vma .initrd=0x3000000 \
        "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" "/tmp/linux.efi"

    # Sign the resulting binary
    # First make sure the drive is mounted
    umount /dev/sda || true
    umount /dev/sda1 || true
    mount /dev/sda /mnt || mount /dev/sda1 /mnt || (echo "Secure boot keys not found; exiting" && sleep 5 && exit);

    sbsign --key=/mnt/DB.key --cert=/mnt/DB.crt --output /boot/efi/EFI/debian/VxLinux-signed.efi /tmp/linux.efi

    # Now install it 
    bash "${VX_FUNCTIONS_ROOT}/setup-boot-entry.sh"
else
    # On a surface we just need to setup the right GRUB entry
    chmod +w /boot/grub/grub.cfg
    cp /vx/admin/config/grub.cfg /boot/grub/grub.cfg

    echo "menuentry 'VxLinux' {
        load_video
        insmod gzio
        if [ x\$grub_platform = xxen ]; then insmod xzio; insmod lzopio; fi
        insmod part_gpt
        insmod ext2
        echo 'Loading Linux ${KERNEL_VERSION} ...'
        linux /vmlinuz-${KERNEL_VERSION} $(cat /tmp/cmdline)
        echo 'Loading initial ramdisk ...'
        initrd /initrd.img-${KERNEL_VERSION} 
    }" >> /boot/grub/grub.cfg

    chmod -w /boot/grub/grub.cfg
fi


# Reboot into the locked down system
echo "Rebooting in 5s"
sleep 5
systemctl reboot -i
