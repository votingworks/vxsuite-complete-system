#!/bin/bash
set -euo pipefail 

if [ $# -eq 1 ]; then
    wd=$1

    sudo apt -y install signify-openbsd qrencode

    # clear out old keys
    rm -f $wd/key.pub $wd/key.sec

    # Generate the keypair
    signify-openbsd -G -n -p $wd/key.pub -s $wd/key.sec

    # Output the public key for enrollment into another device
    qrencode -t UTF8 -r $wd/key.pub -o -
else 
    echo "Usage: ./setup-signify [directory]"
    exit;
fi

