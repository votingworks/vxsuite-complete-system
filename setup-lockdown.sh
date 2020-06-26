#!/bin/bash

set -euo pipefail

# remove all unnecessary packages
apt remove -y adduser adium-theme-ubuntu adwaita-icon-theme anacron apg app-install-data-partner apport apport-gtk apport-symptoms

# disable all passwords
sudo passwd -l root
sudo passwd -l $(whoami)
sudo passwd -l vx-ui
sudo passwd -l vx-services

# set password for vx-admin
echo "Setting password for the admin account:\n"
sudo passwd vx-admin
