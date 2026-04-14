#!/bin/bash

LVM_BUILD_MOUNT_PATH="/vxbuild"
LVM_DEVICE_PATH="/dev/Vx-vg/vxbuild"

# Various files and directories to clean up during
# VM shutdown in the build process
/usr/bin/find "$(realpath /home/vx)" -mindepth 1 -delete
/usr/bin/rm -f /var/log/*.log
/usr/bin/rm -f /var/log/syslog
/usr/bin/rm -f /var/log/votingworks/*

# fstrim the build volume. It must be mounted or space won't
# be reclaimed
# unmount the LVM build volume
# Remove it from /etc/fstab
# Remove the LVM volume so space can be used by /var later
if mountpoint -q "${LVM_BUILD_MOUNT_PATH}"; then
  fstrim "${LVM_BUILD_MOUNT_PATH}"
  umount "${LVM_BUILD_MOUNT_PATH}"
  sed -i -e /vxbuild/d /etc/fstab
  if lvdisplay "${LVM_DEVICE_PATH}"; then
    lvremove -f /dev/Vx-vg/vxbuild
  fi
fi

/usr/bin/systemctl disable vx-cleanup.service

exit 0
