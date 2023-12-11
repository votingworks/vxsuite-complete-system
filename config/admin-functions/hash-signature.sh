#!/bin/bash

echo "Retrieving image signature..."
sha256sum /dev/mapper/Vx--vg-root
echo ""

read -p "Press enter once you have recorded the image signature."
