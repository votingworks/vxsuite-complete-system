#!/bin/bash

set -euo pipefail

sudo apt install -y unclutter mingetty

# turn off automatic updates
sudo cp config/20auto-upgrades /etc/apt/apt.conf.d/

# make sure machine never shuts down on idle, and does shut down on power key (no hibernate or anything.)
sudo cp config/logind.conf /etc/systemd/

# create users, no common group, specified uids.
sudo useradd -u 750 -m -d /vx-services vx-services
sudo useradd -u 751 -m -d /vx-ui -s /bin/bash vx-ui
sudo useradd -u 752 -m -d /vx-admin -s /bin/bash vx-admin

# copy service code
sudo cp -rp run-*.sh frontends components /vx-services

# make sure vx-services has pipenv
sudo -u vx-services -i pip3 install pipenv

# copy the printer configuration so frontend can use it in kiosk browser
sudo cp config/printer-autoconfigure.json /vx-ui/
sudo cp config/hp-laserjet_pro_m404-m405-ps.ppd /vx-ui/

# copy the .bash_profile and .xinitrc for vx-ui auto start
sudo cp config/ui_bash_profile /vx-ui/.bash_profile
sudo cp config/xinitrc /vx-ui/.xinitrc

# admin function scripts
sudo cp config/admin_bash_profile /vx-admin/.bash_profile
sudo cp -rp config/admin-functions /vx-admin/admin-functions

# machine configuration
sudo mkdir -p /vx-config
sudo cp config/read-vx-machine-config.sh /vx-config/

# permissions on directories
sudo chown -R vx-services:vx-services /vx-services
sudo chmod -R u=rwX /vx-services
sudo chmod -R go-rwX /vx-services

sudo chown -R vx-ui:vx-ui /vx-ui
sudo chmod -R u=rwX /vx-ui
sudo chmod -R go-rwX /vx-ui

sudo chown -R vx-admin:vx-admin /vx-admin
sudo chmod -R u=rwX /vx-admin
sudo chmod -R go-rwX /vx-admin

# config readable by services, writable by admin, nothing by anyone else
sudo chown -R vx-admin:vx-services /vx-config
sudo chmod -R u=rwX /vx-config
sudo chmod -R g=rX /vx-config
sudo chmod -R o-rwX /vx-config

# non-graphical login
sudo systemctl set-default multi-user.target

# setup auto login
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo cp config/override.conf /etc/systemd/system/getty@tty1.service.d/override.conf
sudo systemctl daemon-reload

# turn off grub
sudo cp config/grub /etc/default/grub
sudo update-grub

# turn off network
timedatectl set-ntp no
sudo nmcli networking off

# delete any remembered existing network connections (e.g. wifi passwords)
sudo rm -f /etc/NetworkManager/system-connections/*

echo "Successfully setup machine."
