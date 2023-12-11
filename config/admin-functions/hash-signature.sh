#!/bin/bash

echo "Retrieving image signature (this may take some time)..."
sha256sum /dev/mapper/Vx--vg-root
echo ""

read -p "Press enter once you have recorded the image signature."

exit 0;
