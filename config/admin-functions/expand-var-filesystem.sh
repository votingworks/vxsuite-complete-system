#!/bin/bash

set -euo pipefail

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
growpart "/dev/${parent_partition}" 3

pvresize $pvs_path

if [[ $volume_to_extend != "NONE" ]]; then
  lvextend -r -l +100%FREE ${volume_to_extend}
fi

exit 0;
