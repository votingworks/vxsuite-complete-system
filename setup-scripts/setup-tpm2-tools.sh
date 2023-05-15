#!/bin/bash

set -euo pipefail 

# libengine-tpm2-tss-openssl is found in bullseye-backports, which we add here but assign the
# lowest possible priority to, to ensure that we only pull from it when absolutely necessary
sudo sh -c 'echo "\ndeb http://http.us.debian.org/debian bullseye-backports main" >> /etc/apt/sources.list'
sudo sh -c 'echo "Package: *\nPin: release a=bullseye-backports\nPin-Priority: 1" >> /etc/apt/preferences.d/bullseye-backports'
sudo apt update

sudo apt -y install tpm2-tools qrencode
sudo apt -y -t bullseye-backports install libengine-tpm2-tss-openssl
