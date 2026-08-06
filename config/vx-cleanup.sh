#!/bin/bash

LVM_BUILD_MOUNT_PATH="/vxbuild"
LVM_DEVICE_PATH="/dev/Vx-vg/vxbuild"

# Various files and directories to clean up during
# VM shutdown in the build process
/usr/bin/find "$(realpath /home/vx)" -mindepth 1 -delete
/usr/bin/rm -f /var/log/*.log
/usr/bin/rm -f /var/log/syslog
/usr/bin/rm -f /var/log/votingworks/*

# Base debian images give the vx user passwordless sudo so the build can run
# unattended; it must not ship in a machine image. (Harmless once
# setup-machine replaces /etc/sudoers with a config that has no includedir,
# but removed here so the file never reaches a built image at all.)
/usr/bin/rm -f /etc/sudoers.d/99-vxbuild

# Artifacts of an automated build (build-vx-image.sh): the marker that lets
# its in-VM finalize script confirm it is running in a build VM, and a shim
# that makes `logname` work for build scripts run outside a login session.
/usr/bin/rm -f /etc/vx-build-vm
/usr/bin/rm -rf /usr/local/lib/vxbuild-shim

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
