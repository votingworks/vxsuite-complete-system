#!/bin/bash

LVM_BUILD_MOUNT_PATH="/vxbuild"
LVM_DEVICE_PATH="/dev/Vx-vg/vxbuild"

# Various files and directories to clean up during
# VM shutdown in the build process
/usr/bin/find "$(realpath /home/vx)" -mindepth 1 -delete
/usr/bin/rm -rf /var/opt/code
/usr/bin/rm -f /var/log/*.log
/usr/bin/rm -f /var/log/syslog
/usr/bin/rm -f /var/log/votingworks/*

# unmount the LVM build volume
# Remove it from /etc/fstab
# Remove the LVM volume
if mountpoint -q "${LVM_BUILD_MOUNT_PATH}"; then
  umount "${LVM_BUILD_MOUNT_PATH}"
  sed -i -e /vxbuild/d /etc/fstab
  if lvdisplay "${LVM_DEVICE_PATH}"; then
    lvremove -f /dev/Vx-vg/vxbuild
  fi
fi


/usr/bin/systemctl disable vx-cleanup.service

exit 0
