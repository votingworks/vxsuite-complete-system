#!/bin/bash

if [[ $1 == "noninteractive" ]]; then
  hash=$(sha256sum /dev/mapper/Vx--vg-root | cut -d' ' -f1)
  echo "$hash"
else
  echo "Retrieving image signature (this may take some time)..."
  sha256sum /dev/mapper/Vx--vg-root
  echo ""
  read -p "Press enter once you have recorded the image signature."
fi

exit 0;
