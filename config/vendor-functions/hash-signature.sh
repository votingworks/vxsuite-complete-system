#!/bin/bash

verity_hash=$(cat /proc/cmdline | awk -F'verity.hash=' '{print $2}' | cut -d' ' -f1)
verity_result="UNVERIFIED"

if [[ ! -z ${verity_hash} ]]; then
  verity_result="$verity_hash"

  # If we need to provide a live verification, the code below can enable that functionality
  # For now, we are simply returning the hash found in /proc/cmdline
  #verity_root_device=$(cat /proc/cmdline | awk -F'verity.rootdev=' '{print $2}' | cut -d' ' -f1)
  #verity_hash_device=$(cat /proc/cmdline | awk -F'verity.hashdev=' '{print $2}' | cut -d' ' -f1)
  #verify_result=$(veritysetup verify ${verity_root_device} ${verity_hash_device} ${verity_hash} > /dev/null 2>&1)
  #if [[ $? -eq 0 ]]; then
    #verity_result="$verity_hash"
  #fi
fi

if [[ $1 == "noninteractive" ]]; then
  echo "$verity_result"
else
  echo "$verity_result"
  read -p "Press enter once you have recorded the image signature."
fi

exit 0;
