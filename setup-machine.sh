#!/bin/bash

set -euo pipefail

# which kind of machine are we setting up?
echo "Welcome to VxSuite. THIS IS A DESTRUCTIVE SCRIPT. Ctrl-C right now if you don't know for sure what you're doing."
echo "Which machine are we building today?"

CHOICES=('')

echo
echo "${#CHOICES[@]}. Election Manager"
CHOICES+=('election-manager')

echo "${#CHOICES[@]}. Ballot Scanner"
CHOICES+=('ballot-scanner')

echo "${#CHOICES[@]}. Ballot Marking Device (BMD)"
CHOICES+=('bmd')

echo "${#CHOICES[@]}. Ballot Activation System (BAS)"
CHOICES+=('bas')

echo
read -p "Select machine: " CHOICE_INDEX

if [ "${CHOICE_INDEX}" -ge "${#CHOICES[@]}" ] || [ "${CHOICE_INDEX}" -lt 1 ]
then
    echo "You need to select a valid machine type."
    exit 1
fi

CHOICE=${CHOICES[$CHOICE_INDEX]}

echo "Excellent, let's set up ${CHOICE}."

sudo apt install -y unclutter mingetty pmount brightnessctl

# simple window manager and remove all contextual info
sudo apt install -y openbox

# turn off automatic updates
sudo cp config/20auto-upgrades /etc/apt/apt.conf.d/

# make sure machine never shuts down on idle, and does shut down on power key (no hibernate or anything.)
sudo cp config/logind.conf /etc/systemd/

# create users, no common group, specified uids.
sudo useradd -u 750 -m -d /vx-services vx-services
sudo useradd -u 751 -m -d /vx-ui -s /bin/bash vx-ui
sudo useradd -u 752 -m -d /vx-admin -s /bin/bash vx-admin

# a vx group for all vx users
sudo groupadd -g 800 vx-group
sudo usermod -aG vx-group vx-ui
sudo usermod -aG vx-group vx-services
sudo usermod -aG vx-group vx-admin

# remove all files created by default
sudo rm -rf /vx-services/* /vx-ui/* /vx-admin/*

# Let vx-admin read logs
sudo usermod -aG adm vx-admin

# Let some users mount/unmount usb disks
if [ "${CHOICE}" != "bmd" ] && [ "${CHOICE}" != "bas" ] 
then
    sudo usermod -aG plugdev vx-ui
fi
sudo usermod -aG plugdev vx-admin

# let vx-ui manage printers
sudo usermod -aG lpadmin vx-ui

# let vx-services scan
if [ "${CHOICE}" != "bmd" ] && [ "${CHOICE}" != "bas" ] 
then
    sudo cp config/49-sane-missing-scanner.rules /etc/udev/rules.d/
    sudo usermod -aG scanner vx-services
fi

# remove components we don't need
if [ "${CHOICE}" = "election-manager" ]
then
    echo "removing unnecessary code for Election Manager."
    rm -rf components/module-smartcards components/module-scan components/module-usbstick
fi

if [ "${CHOICE}" = "bmd" ] || [ "${CHOICE}" = "bas" ]
then
    echo "removing unnecessary code for BMD/BAS."
    rm -rf components/module-scan
    rm -rf frontends/bsd frontends/election-manager
fi

# copy service code
sudo cp -rp run-*.sh frontends components /vx-services

# make sure vx-services has pipenv
sudo -u vx-services -i pip3 install pipenv

# copy the printer configuration so frontend can use it in kiosk browser
sudo mkdir -p /vx-ui/.vx
sudo cp -r printing /vx-ui/.vx/

sudo cp run-kiosk-browser.sh /vx-ui/.vx/
sudo cp run-kiosk-browser-forever-and-log.sh /vx-ui/.vx/

# copy the .bash_profile and .xinitrc for vx-ui auto start
sudo cp config/ui_bash_profile /vx-ui/.bash_profile

sudo cp config/xinitrc /vx-ui/.xinitrc

# admin function scripts
sudo cp config/admin_bash_profile /vx-admin/.bash_profile
sudo cp -rp config/admin-functions /vx-admin/admin-functions

# machine configuration
sudo mkdir -p /vx-config
sudo cp config/read-vx-machine-config.sh /vx-config/

# record the machine type in the configuration (-E keeps the environment variable around, CHOICE prefix sends it in)
CHOICE="${CHOICE}" sudo -E sh -c 'echo "${CHOICE}" > /vx-config/machine-type'

# code version
sudo sh -c 'git rev-parse HEAD > /vx-config/code-version'

# machine ID
sudo sh -c 'echo "0000" > /vx-config/machine-id'

# app mode & speech synthesis
if [ "${CHOICE}" = "bmd" ]
then
    sudo sh -c 'echo "VxMark" > /vx-config/app-mode'

    bash setup-speech-synthesis.sh
fi

# vx-ui OpenBox configuration
sudo mkdir -p /vx-ui/.config/openbox
sudo cp config/openbox-menu.xml /vx-ui/.config/openbox/menu.xml
sudo cp config/openbox-rc.xml /vx-ui/.config/openbox/rc.xml

# If surface go, set proper resolution (1x not 2x)
PRODUCT_NAME=`sudo dmidecode -s system-product-name`
if [ "$PRODUCT_NAME" == "Surface Go" ]
then
    sudo cp config/surface-go-monitors.xml /vx-ui/.config/monitors.xml
fi


# permissions on directories
sudo chown -R vx-services:vx-services /vx-services
sudo chmod -R u=rwX /vx-services
sudo chmod -R go-rwX /vx-services

sudo chown -R vx-ui:vx-ui /vx-ui
sudo chmod -R u=rwX /vx-ui
sudo chmod -R go-rwX /vx-ui

# make the run scripts and configuration not modifiable by vx-ui
sudo chown -R vx-services:vx-ui /vx-ui/.vx
sudo chmod -R g+rX /vx-ui/.vx

sudo chown -R vx-admin:vx-admin /vx-admin
sudo chmod -R u=rwX /vx-admin
sudo chmod -R go-rwX /vx-admin

# config readable & executable by all vx users, writable by admin.
sudo chown -R vx-admin:vx-group /vx-config
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

# remove all network drivers. Buh bye.
sudo apt purge -y network-manager
sudo rm -rf /lib/modules/*/kernel/drivers/net/*

# delete any remembered existing network connections (e.g. wifi passwords)
sudo rm -f /etc/NetworkManager/system-connections/*

# set up the service for the selected machine type
sudo cp config/vx-${CHOICE}.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/vx-${CHOICE}.service
sudo systemctl enable vx-${CHOICE}.service
sudo systemctl start vx-${CHOICE}.service


echo "Successfully setup machine."


## NOW LOCK IT DOWN

USER=$(whoami)

# remove all unnecessary packages
sudo apt remove -y --auto-remove ubuntu-gnome-desktop
sudo apt remove -y git firefox snapd
sudo apt autoremove -y

# set password for vx-admin
echo "Setting password for the admin account:\n"
while true; do
    sudo passwd vx-admin && break
done

# disable all passwords
sudo passwd -l root
sudo passwd -l ${USER}
sudo passwd -l vx-ui
sudo passwd -l vx-services

# move in our sudo file, which removes sudo'ing except for granting vx-admin a very specific set of privileges
sudo cp config/sudoers /etc/sudoers

# FIXME: clean up source code
cd
rm -rf *

echo "Done, rebooting in 5s."

sleep 5

reboot
