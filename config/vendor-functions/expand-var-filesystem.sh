#!/bin/bash

set -euo pipefail

# Find the mapped device for /var, need this to look up the LV later
var_map=$( df -l /var | grep mapper | awk '{print $1}' )

# This identifies the PV used in our config. It assumes our Vx naming convention
pvs_path=$( pvs | grep Vx | awk '{print $1}' )

# Using the PV path, get the parent device path we'll need for resizing
parent_partition=$( lsblk -ndo pkname ${pvs_path} )

volume_to_extend="NONE"

# Determine the volume to extend based on whether encrypted /var is used or not
if [[ $var_map =~ "var_decrypted" ]]; then
  volume_to_extend=$( grep var_decrypted /etc/crypttab | awk '{print $2}' )
else
  volume_to_extend=$( lvdisplay ${var_map} | grep "LV Path" | awk '{print $3}' )
fi

# Vx convention: we always expect partition 3
# if this changes in the future, we'll need to add logic to detect
growpart "/dev/${parent_partition}" 3 || true

# LVM_SYSTEM_DIR is necessary for locked down images since the default of /etc/lvm is 
# read-only in a locked down image
LVM_SYSTEM_DIR=/home/.lvm pvresize $pvs_path

# This extends the logical volume to the max available space (as created by the previous
# commands). We pass along the empty passphrase for systems using encrypted /var,
# and it has no effect on systems not using encrypted /var
if [[ $volume_to_extend != "NONE" ]]; then
  echo "" | LVM_SYSTEM_DIR=/home/.lvm lvextend -r -l +100%FREE ${volume_to_extend}
fi

if [[ -f "${VX_CONFIG_ROOT}/EXPAND_VAR" ]]; then
  rm -f "${VX_CONFIG_ROOT}/EXPAND_VAR"
fi

exit 0;
