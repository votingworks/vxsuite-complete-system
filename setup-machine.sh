#!/bin/bash

# /vx/ui --> home directory for the vx-ui user (rw with symlink for ro files)
# /vx/services --> home directory for the vx-services user (rw with symlink for ro files)
# /vx/admin --> home directory for the vx-admin user (rw with symlink for ro files)
# /vx/code --> all the executable code (ro)
# /vx/data --> all the scans and sqlite database for services
# /vx/config --> machine configuration that spans all the users.

set -euo pipefail

if [ $UID != 0 ]; then
    echo "Please run this script as root (i.e. with sudo)"
    exit 1
fi

if uname -a | grep Debian; then
	export DISTRO="Debian"
else
	export DISTRO="Ubuntu"
fi

# which kind of machine are we setting up?
echo "Welcome to VxSuite. THIS IS A DESTRUCTIVE SCRIPT. Ctrl-C right now if you don't know for sure what you're doing."
echo "Which machine are we building today?"

CHOICES=('')
MODEL_NAMES=('')

echo
echo "${#CHOICES[@]}. Election Manager"
CHOICES+=('election-manager')
MODEL_NAMES+=('VxAdmin')

echo "${#CHOICES[@]}. Ballot Scanner"
CHOICES+=('bsd')
MODEL_NAMES+=('VxCentralScan')

echo "${#CHOICES[@]}. Ballot Marking Device (BMD)"
CHOICES+=('bmd')
MODEL_NAMES+=('VxMark')

echo "${#CHOICES[@]}. Ballot Activation System (BAS)"
CHOICES+=('bas')
MODEL_NAMES+=('VxEncode')

echo "${#CHOICES[@]}. Precinct Scanner"
CHOICES+=('precinct-scanner')
MODEL_NAMES+=('VxScan')

echo
read -p "Select machine: " CHOICE_INDEX

if [ "${CHOICE_INDEX}" -ge "${#CHOICES[@]}" ] || [ "${CHOICE_INDEX}" -lt 1 ]
then
    echo "You need to select a valid machine type."
    exit 1
fi

CHOICE=${CHOICES[$CHOICE_INDEX]}
MODEL_NAME=${MODEL_NAMES[$CHOICE_INDEX]}

echo "Excellent, let's set up ${CHOICE}."

# pre-flight checks to ensure we have everything we need
if [ "${CHOICE}" == "precinct-scanner" ]
then
    if ! which plustekctl >/dev/null 2>&1
    then
        echo "error: plustekctl was not found in PATH=${PATH}" >&2
        echo -e "Please install it from \e[4mhttps://github.com/votingworks/plustekctl\e[0m." >&2
        exit 1
    fi
fi

apt install -y unclutter mingetty pmount brightnessctl

# simple window manager and remove all contextual info
apt install -y openbox

# Get some extras for Debian lockdown
if [[ $DISTRO == "Debian" ]]; then
	apt install -y rsync cups cryptsetup xserver-xorg-core x11-common xinit sbsigntool
	chown :lpadmin /sbin/lpinfo
	echo "export PATH=$PATH:/sbin" | tee -a /etc/bash.bashrc
fi

# turn off automatic updates
cp config/20auto-upgrades /etc/apt/apt.conf.d/

# make sure machine never shuts down on idle, and does shut down on power key (no hibernate or anything.)
cp config/logind.conf /etc/systemd/

echo "Creating necessary directories"
# directory structure
mkdir -p /vx
mkdir -p /var/vx
mkdir -p /var/vx/data/module-scan
mkdir -p /var/vx/data/module-sems-converter

ln -sf /var/vx/data /vx/data

echo "Creating users"
# create users, no common group, specified uids.
id -u vx-services &> /dev/null || useradd -u 750 -m -d /var/vx/services vx-services
id -u vx-ui &> /dev/null || useradd -u 751 -m -d /var/vx/ui -s /bin/bash vx-ui
id -u vx-admin &> /dev/null || useradd -u 752 -m -d /var/vx/admin -s /bin/bash vx-admin

echo "Sym-linking folders that need to be mutable"

# These user folders were created on the /var directory so they can
# be mutable. Link them to the old path on the readonly root. 
ln -sf /var/vx/services /vx/services
ln -sf /var/vx/ui /vx/ui
ln -sf /var/vx/admin /vx/admin

# a vx group for all vx users
getent group vx-group || groupadd -g 800 vx-group
usermod -aG vx-group vx-ui
usermod -aG vx-group vx-services
usermod -aG vx-group vx-admin

# remove all files created by default
rm -rf /vx/services/* /vx/ui/* /vx/admin/*

# Let vx-admin read logs
usermod -aG adm vx-admin
usermod -aG adm vx-ui

# Set up log config
bash setup-scripts/setup-logging.sh

# Let some users mount/unmount usb disks
if [ "${CHOICE}" != "bmd" ] && [ "${CHOICE}" != "bas" ] 
then
    usermod -aG plugdev vx-ui
fi
usermod -aG plugdev vx-admin

# let vx-ui manage printers
usermod -aG lpadmin vx-ui

# let vx-services scan
if [ "${CHOICE}" != "bmd" ] && [ "${CHOICE}" != "bas" ] 
then
    cp config/49-sane-missing-scanner.rules /etc/udev/rules.d/
    usermod -aG scanner vx-services
fi

echo "Setting up the code"
# copy code into the right place
./build.sh "${CHOICE}"
mv build/${CHOICE} /vx/code

# temporary hack cause of precinct-scanner runtime issue
rm /vx/code/vxsuite # it's a symlink
cp -rp vxsuite /vx/code/

# symlink the code and run-*.sh in /vx/services
ln -s /vx/code/vxsuite /vx/services/vxsuite
ln -s /vx/code/run-${CHOICE}.sh /vx/services/run-${CHOICE}.sh

# make sure vx-services has pipenv
-u vx-services -i pip3 install pipenv

# symlink printer config and run scripts for vx-ui
mkdir -p /vx/ui/.vx
ln -s /vx/code/printing /vx/ui/.vx/printing
ln -s /vx/code/run-kiosk-browser.sh /vx/ui/.vx/run-kiosk-browser.sh
ln -s /vx/code/run-kiosk-browser-forever-and-log.sh /vx/ui/.vx/run-kiosk-browser-forever-and-log.sh

# symlink appropriate vx/ui files
ln -s /vx/code/config/ui_bash_profile /vx/ui/.bash_profile
ln -s /vx/code/config/Xresources /vx/ui/.Xresources
ln -s /vx/code/config/xinitrc /vx/ui/.xinitrc

# symlink the GTK .settings.ini
mkdir -p /vx/ui/.config/gtk-3.0
ln -s /vx/code/config/gtksettings.ini /vx/ui/.config/gtk-3.0/settings.ini

# Hooks for dm-verity
cp config/dmverity-root.hook /etc/initramfs-tools/hooks/dmverity-root
cp config/dmverity-root.script /etc/initramfs-tools/scripts/local-premount/dmverity-root

# admin function scripts
ln -s /vx/code/config/admin_bash_profile /vx/admin/.bash_profile
ln -s /vx/code/config/admin-functions /vx/admin/admin-functions

# Make sure our cmdline file is readable by vx-admin
mkdir -p /vx/admin/config
cp config/cmdline /vx/code/config/cmdline
cp config/logo.bmp /vx/code/config/logo.bmp
ln -s /vx/code/config/cmdline /vx/admin/config/cmdline
ln -s /vx/code/config/logo.bmp /vx/admin/config/logo.bmp

# machine configuration
# TODO: This should be writeable right?
mkdir -p /var/vx/config
ln -sf /var/vx/config /vx/config

ln -s /vx/code/config/read-vx-machine-config.sh /vx/config/read-vx-machine-config.sh

# record the machine type in the configuration (-E keeps the environment variable around, CHOICE prefix sends it in)
CHOICE="${CHOICE}" -E sh -c 'echo "${CHOICE}" > /vx/config/machine-type'

# machine manufacturer
echo "VotingWorks" > /vx/config/machine-manufacturer

# machine model name i.e. "VxScan"
echo "${MODEL_NAME}" > /vx/config/machine-model-name

# code version, e.g. "2021.03.29-d34db33fcd"
echo "$(date +%Y.%m.%d)-$(git rev-parse HEAD | cut -c -10)" > /vx/config/code-version

# code tag, e.g. "m11c-rc3"
git tag --points-at HEAD > /vx/config/code-tag

# machine ID
echo "0000" > /vx/config/machine-id

# app mode & speech synthesis
if [ "${CHOICE}" = "bmd" ]
then
    echo "MarkAndPrint" > /vx/config/app-mode
    bash setup-scripts/setup-speech-synthesis.sh
fi

# vx-ui OpenBox configuration
mkdir -p /vx/ui/.config/openbox
ln -s /vx/code/config/openbox-menu.xml /vx/ui/.config/openbox/menu.xml
ln -s /vx/code/config/openbox-rc.xml /vx/ui/.config/openbox/rc.xml

# If surface go, set proper resolution (1x not 2x)
PRODUCT_NAME=$(dmidecode -s system-product-name)
if [ "$PRODUCT_NAME" == "Surface Go" ]
then
    ln -s /vx/code/config/surface-go-monitors.xml /vx/ui/.config/monitors.xml
fi

# setup tpm2-totp
bash setup-scripts/setup-tpm2-totp.sh


# permissions on directories
# TODO: I think we only need to change the permissions for stuff in /var/ 
chown -R vx-services:vx-services /var/vx/services
chmod -R u=rwX /var/vx/services
chmod -R go-rwX /var/vx/services

chown -R vx-ui:vx-ui /var/vx/ui
chmod -R u=rwX /var/vx/ui
chmod -R go-rwX /var/vx/ui

chown -R vx-admin:vx-admin /var/vx/admin
chmod -R u=rwX /var/vx/admin
chmod -R go-rwX /var/vx/admin

chown -R vx-services:vx-services /var/vx/data
chmod -R u=rwX /var/vx/data
chmod -R go-rwX /var/vx/data

# config readable & executable by all vx users, writable by admin.
chown -R vx-admin:vx-group /var/vx/config
chmod -R u=rwX /var/vx/config
chmod -R g=rX /var/vx/config
chmod -R o-rwX /var/vx/config

# non-graphical login
systemctl set-default multi-user.target

# setup auto login
mkdir -p /etc/systemd/system/getty@tty1.service.d
cp config/override.conf /etc/systemd/system/getty@tty1.service.d/override.conf
systemctl daemon-reload

# turn off grub
cp config/grub /etc/default/grub
update-grub

# turn off network
timedatectl set-ntp no

if [[  $DISTRO == "Ubuntu" ]]; then
	nmcli networking off
fi

# remove all network drivers. Buh bye.
apt purge -y network-manager
rm -rf /lib/modules/*/kernel/drivers/net/*

# delete any remembered existing network connections (e.g. wifi passwords)
rm -f /etc/NetworkManager/system-connections/*

# set up the service for the selected machine type
cp config/vx-${CHOICE}.service /etc/systemd/system/
chmod 644 /etc/systemd/system/vx-${CHOICE}.service
systemctl enable vx-${CHOICE}.service
systemctl start vx-${CHOICE}.service


echo "Successfully setup machine."


## NOW LOCK IT DOWN

USER=$(whoami)

# remove all unnecessary packages
if [[ $DISTRO == "Ubuntu" ]] ; then
	apt remove -y ubuntu-desktop
fi

apt remove -y git firefox snapd
apt autoremove -y

# set password for vx-admin
echo "Setting password for the admin account:"
echo
while true; do
    passwd vx-admin && break
done

# disable all passwords
passwd -l root
passwd -l ${USER}
passwd -l vx-ui
passwd -l vx-services

# move in our sudo file, which removes sudo'ing except for granting vx-admin a very specific set of privileges
cp config/sudoers /etc/sudoers

# FIXME: clean up source code
cd
rm -rf *

echo "Done, rebooting in 5s."

sleep 5

reboot
