#!/bin/bash
#
#

if [ ! -e /dev/vxvg/var_encrypted ]; then
    echo "No var_encrypted partition detected in LVM"
    exit 1
fi

if [ -e /dev/mapper/var_decrypted ]; then
    echo "Looks like encrypted var is already set up"
    exit 1
fi

# set up and format LUKS partition
echo -n "insecure" | cryptsetup luksFormat -q --cipher aes-xts-plain64 --key-size 512 --hash sha256 /dev/vxvg/var_encrypted
echo -n "insecure" | cryptsetup open --type luks /dev/vxvg/var_encrypted var_decrypted
mkfs.ext4 /dev/mapper/var_decrypted

# copy over var
mkdir /mnt/newvar
mount /dev/mapper/var_decrypted /mnt/newvar
rsync -a /var/ /mnt/newvar/
umount /mnt/newvar/
rm -rf /var

# mount new var
mkdir /var
mount /dev/mapper/var_decrypted /var
echo "/dev/mapper/var_decrypted /var ext4 defaults 0 2" >> /etc/fstab
echo "var_decrypted /dev/vxvg/var_encrypted none luks" >> /etc/crypttab

