#!/bin/bash
set -euo pipefail 

sudo apt -y install signify-openbsd qrencode

# clear out old keys
rm -f /vx/config/key.pub /vx/config/key.sec

# Generate the keypair
signify-openbsd -G -n -p /vx/config/key.pub -s /vx/config/key.sec

# Output the public key for enrollment into another device
qrencode -t UTF8 -r /vx/config/key.pub -o -
