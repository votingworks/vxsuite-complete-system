#!/bin/bash

APP_TYPE='VxMark'
BRANCH='latest'

echo "Welcome to VxDev, which app would you like to configure this machine for?"
CHOICES=('')
echo
echo "${#CHOICES[@]}. VxAdmin"
CHOICES+=('VxAdmin')

echo "${#CHOICES[@]}. VxCentralScan"
CHOICES+=('VxCentralScan')

echo "${#CHOICES[@]}. VxAdmin and VxCentralScan"
CHOICES+=('VxAdminCentralScan')

echo "${#CHOICES[@]}. VxMark"
CHOICES+=('VxMark')

echo "${#CHOICES[@]}. VxScan"
CHOICES+=('VxScan')

echo "${#CHOICES[@]}. VxMarkScan"
CHOICES+=('VxMarkScan')

echo
read -p "Select Application: " CHOICE_INDEX

if [ "${CHOICE_INDEX}" -ge "${#CHOICES[@]}" ] || [ "${CHOICE_INDEX}" -lt 1 ]
then
    echo "You need to select a valid machine type."
    exit 1
fi

CHOICE=${CHOICES[$CHOICE_INDEX]}


cd /vx/code/vxsuite-complete-system

# Fetch the latest code
git checkout main > /dev/null 2>&1
git pull > /dev/null

# Update the configuration script and run it to fetch and apply any new updates to VxDev
sudo cp vxdev/vxdev-configuration.sh /vx/scripts/.
bash /vx/scripts/vxdev-configuration.sh


FAVORITE_ICONS=''

if [[ $CHOICE == 'VxMark' ]]; then
	sudo sh -c 'echo "MarkAndPrint" > /vx/config/app-mode'
	sudo cp vxdev/run-vxmark.desktop /usr/share/applications/.
	FAVORITE_ICONS="'run-vxmark.desktop'"
fi
if [[ $CHOICE == 'VxScan' ]]; then
	sudo cp vxdev/run-vxscan.desktop /usr/share/applications/.
	FAVORITE_ICONS="'run-vxscan.desktop'"
fi
if [[ $CHOICE == 'VxMarkScan' ]]; then
	sudo cp vxdev/run-vxmarkscan.desktop /usr/share/applications/.
	FAVORITE_ICONS="'run-vxmarkscan.desktop'"
fi
if [[ $CHOICE == 'VxAdmin' ]]; then
	sudo cp vxdev/run-vxadmin.desktop /usr/share/applications/.
	FAVORITE_ICONS="'run-vxadmin.desktop'"
fi
if [[ $CHOICE == 'VxCentralScan' ]]; then
	sudo cp vxdev/run-vxcentralscan.desktop /usr/share/applications/.
	FAVORITE_ICONS="'run-vxcentralscan.desktop'"
fi
if [[ $CHOICE == 'VxAdminCentralScan' ]]; then
	sudo cp vxdev/run-vxcentralscan.desktop /usr/share/applications/.
	sudo cp vxdev/run-vxadmin.desktop /usr/share/applications/.
	FAVORITE_ICONS="'run-vxadmin.desktop', 'run-vxcentralscan.desktop'"
fi

# Set desktop icons as favorites so they appear in the doc
gsettings set org.gnome.shell favorite-apps "[$FAVORITE_ICONS, 'update-code.desktop', 'update-vxdev.desktop', 'org.gnome.Screenshot.desktop', 'firefox-esr.desktop', 'org.gnome.Nautilus.desktop', 'kazam.desktop', 'org.gnome.Terminal.desktop']"

CHOICE="${CHOICE}" sudo -E sh -c 'echo "${CHOICE}" > /vx/config/machine-type'

# vxdev daemons need this now, unlike setup_machine.sh, we use the CHOICE var
MODEL_NAME="${CHOICE}" sudo -E sh -c 'echo "${MODEL_NAME}" > /vx/config/machine-model-name'


echo "Done, this window will close in 3 seconds"
