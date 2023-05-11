#!/bin/bash

set -euo pipefail 

# Where libengine-tpm2-tss-openssl lives
sudo sh -c 'echo "\ndeb http://http.us.debian.org/debian bullseye-backports main" >> /etc/apt/sources.list'
sudo apt update

sudo apt -y install tpm2-tools qrencode libengine-tpm2-tss-openssl
