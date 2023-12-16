#!/bin/bash
set -euo pipefail 

: "${VX_FUNCTIONS_ROOT:="$(dirname "$0")"}"
: "${VX_CONFIG_ROOT:="/vx/config"}"

echo "Is this image going on a Surface Go? [y/N]:" 

read -r is_surface_go

if [[ $is_surface_go == 'y' || $is_surface_go == 'Y' ]]; then
    surface=1
    echo "Surface Go device. Locking down with GRUB."
else
    surface=0
    echo "Locking down with a unified kernel binary."
fi

echo "Are you sure you want to proceed with lockdown? [Y/n]:" 

read -r answer

if [[ $answer == 'n' || $answer == 'N' ]]; then
    echo "Not locking down. Exiting..."
    sleep 3
    exit
fi

# We don't need to sign i915 since it is signed by Debian's Secure Boot key
# and we have access to that under Secure Boot. 
# However, if we do ever need to use an unsigned module, the below code 
# will sign with the VotingWorks key.
# You would just add modules to the var, e.g. modules_to_sign="i915 mod2 mod3"
modules_to_sign=""
if [[ $surface == 0 ]] && [[ -n $modules_to_sign ]]; then
  read -s -p "Please enter the passphrase for the secure boot key: " KBUILD_SIGN_PIN

  export KBUILD_SIGN_PIN

  umount /dev/sda || true
  umount /dev/sda1 || true
  mount /dev/sda /mnt || mount /dev/sda1 /mnt || (echo "Secure boot keys not found; exiting" && sleep 5 && exit);

  for module in ${modules_to_sign}
  do
    if modinfo -n ${module} 2>&1 > /dev/null; then
      /usr/src/linux-kbuild-6.1/scripts/sign-file sha256 /mnt/DB.key /mnt/DB.crt $(modinfo -n ${module})
    fi
  done
fi

update-initramfs -u

# change fstab to mount the root partition as read-only the next time it boots
# we have to do this before we remount as read-only ourselves,
# and of course before we dm-verity the root partition
sed -i -e "s/errors=/ro,errors=/" /etc/fstab

# Remount / so it can't change while we're doing the veritysetup
cd /tmp
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
	--add-section .loglevel="loglevel=3" --change-section-vma .loglevel=0x50000 \
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
