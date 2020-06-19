#!/bin/bash

set -euo pipefail

# disable all passwords
sudo passwd -l root
sudo passwd -l $(whoami)
sudo passwd -l vx-ui
sudo passwd -l vx-services

# set password for vx-admin
echo "Setting password for the admin account:\n"
sudo passwd vx-admin
