#!/bin/bash

set -euo pipefail

if uname -a | grep Debian; then
	export DISTRO="Debian"
else
	export DISTRO="Ubuntu"
fi

# Debian doesn't add /sbin/ to default path, but it's needed for groupadd and other commands.
# If /sbin/ is already in the path, this won't hurt, and it's just for running this script.
if [[ $DISTRO == "Debian" ]]; then
    export PATH=${PATH}:/sbin/
fi

if ! which plustekctl >/dev/null 2>&1
then
    echo "error: plustekctl was not found in PATH=${PATH}" >&2
    echo -e "Please install it from \e[4mhttps://github.com/votingworks/plustekctl\e[0m." >&2
#    exit 1
fi

echo
echo "Welcome to VxDev, we need to set the admin password for this machine."
while true; do
    read -s -p "Set vx-admin password: " ADMIN_PASSWORD
    echo
    read -s -p "Confirm vx-admin password: " CONFIRM_PASSWORD
    echo
    if [[ "${ADMIN_PASSWORD}" = "${CONFIRM_PASSWORD}" ]]
    then
        echo "Password confirmed."
        break
    else
        echo "Passwords do not match, try again."
    fi
done

echo
echo "The script will take it from here and set up the machine."
echo


sudo apt install -y unclutter mingetty pmount brightnessctl

# simple window manager and remove all contextual info
sudo apt install -y openbox

# Get some extras for Debian lockdown
if [[ $DISTRO == "Debian" ]]; then
	sudo apt install -y rsync cups cryptsetup xserver-xorg-core x11-common xinit sbsigntool
	sudo chown :lpadmin /sbin/lpinfo
	echo "export PATH=$PATH:/sbin" | sudo tee -a /etc/bash.bashrc
fi

# Set up vx-admin user
sudo mkdir -p /vx
id -u vx-admin &> /dev/null || sudo useradd -u 752 -m -d /var/vx/admin -s /bin/bash vx-admin
sudo ln -sf /var/vx/admin /vx/admin
(echo $ADMIN_PASSWORD; echo $ADMIN_PASSWORD) | sudo passwd vx-admin

# make sure machine never shuts down on idle, and does shut down on power key (no hibernate or anything.)
sudo cp config/logind.conf /etc/systemd/

echo "Creating necessary directories"
# directory structure
sudo mkdir -p /vx
sudo mkdir -p /var/vx
sudo mkdir -p /var/vx/code
sudo mkdir -p /var/vx/data/module-scan
sudo mkdir -p /var/vx/data/module-sems-converter
sudo mkdir -p /var/vx/data/admin-service

# machine configuration
# TODO: This should be writeable right?
sudo mkdir -p /var/vx/config
sudo ln -sf /var/vx/config /vx/config

sudo ln -sf /var/vx/data /vx/data
sudo ln -sf /var/vx/code /vx/code

sudo ln -sf /vx/code/config/read-vx-machine-config.sh /vx/config/read-vx-machine-config.sh
sudo ln -sf /home/vx/code/vxsuite-complete-system /vx/code/vxsuite-complete-system

sudo chown -R vx:vx /vx/data
sudo chmod -R ugo=rwX /vx/data

sudo chown -R vx-admin:vx-admin /var/vx/admin
sudo chmod -R u=rwX /var/vx/admin
sudo chmod -R go-rwX /var/vx/admin

sudo chown -R vx-admin:vx-admin /var/vx/config
sudo chmod -R ugo=rwX /var/vx/config

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

sudo cp -rp \
  "${DIR}/../run-scripts/run-kiosk-browser.sh" \
  "${DIR}/../run-scripts/run-kiosk-browser-forever-and-log.sh" \
  "${DIR}/../config" \
  "${DIR}/../printing" \
  "/vx/code"


# Let vx read logs
sudo usermod -aG adm vx

# Set up log config
sudo bash setup-scripts/setup-logging.sh


# Let some users mount/unmount usb disks
sudo usermod -aG plugdev vx

# let vx manage printers
sudo usermod -aG lpadmin vx

sudo cp config/49-sane-missing-scanner.rules /etc/udev/rules.d/
sudo usermod -aG scanner vx

# make sure vx has pipenv
sudo -u vx -i pip3 install pipenv

# admin function scripts
sudo ln -sf /vx/code/config/admin_bash_profile /vx/admin/.bash_profile
sudo ln -sf /vx/code/config/admin-functions /vx/admin/admin-functions

# machine manufacturer
sudo sh -c 'echo "VotingWorks" > /vx/config/machine-manufacturer'

# code version, e.g. "2021.03.29-d34db33fcd"
sudo sh -c 'echo "$(date +%Y.%m.%d)-$(git rev-parse HEAD | cut -c -10)" > /vx/code/code-version'

# code tag, e.g. "m11c-rc3"
sudo sh -c 'git tag --points-at HEAD > /vx/code/code-tag'

# machine ID
sudo sh -c 'echo "0000" > /vx/config/machine-id'

# sudo sh -c 'echo "MarkAndPrint" > /vx/config/app-mode'
bash setup-scripts/setup-speech-synthesis.sh

# vx-ui OpenBox configuration
sudo mkdir -p /vx/ui/.config/openbox
sudo ln -sf /vx/code/config/openbox-menu.xml /vx/ui/.config/openbox/menu.xml
sudo ln -sf /vx/code/config/openbox-rc.xml /vx/ui/.config/openbox/rc.xml

# If surface go, set proper resolution (1x not 2x)
PRODUCT_NAME=`sudo dmidecode -s system-product-name`
if [ "$PRODUCT_NAME" == "Surface Go" ]
then
    sudo ln -sf /vx/code/config/surface-go-monitors.xml /vx/ui/.config/monitors.xml
fi

# update sudoers file to give vx user special permissions
sudo cp vxdev/sudoers /etc/sudoers

# setup tpm2-totp
sudo bash setup-scripts/setup-tpm2-totp.sh

# setup tpm2-tools
sudo bash setup-scripts/setup-tpm2-tools.sh

# turn off time synchronization
sudo timedatectl set-ntp no

# Install app to configure VxDev
bash vxdev/vxdev-configuration.sh

echo "Done with initial VxDev setup! You may now run the "Update and Configure VxDev" program."
