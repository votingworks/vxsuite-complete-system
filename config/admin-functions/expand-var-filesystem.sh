#!/bin/bash

set -euo pipefail

flag_file="/home/VAR_RESIZED"

if [[ -f ${flag_file} ]]; then
  exit 0
fi

var_map=$( df -l /var | grep mapper | awk '{print $1}' )
pvs_path=$( pvs | grep Vx | awk '{print $1}' )
parent_partition=$( lsblk -ndo pkname ${pvs_path} )
volume_to_extend="NONE"

if [[ $var_map =~ "var_decrypted" ]]; then
  volume_to_extend=$( grep var_decrypted /etc/crypttab | awk '{print $2}' )
else
  volume_to_extend=$( lvdisplay ${var_map} | grep "LV Path" | awk '{print $3}' )
fi

# convention: we always expect partition 3
# if this changes in the future, we'll need to add logic to detect
growpart "/dev/${parent_partition}" 3 || touch ${flag_file} && exit 0

pvresize $pvs_path

if [[ $volume_to_extend != "NONE" ]]; then
  echo "insecure" | lvextend -r -l +100%FREE ${volume_to_extend}
  touch ${flag_file}
fi

exit 0;
