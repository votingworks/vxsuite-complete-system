# Sets up the main configuration for VxDev. This file is automatically updated and re-run
# when the VxDev "Update and Configure VxDev" program is run. Any updates to make to live VxDev
# systems should be added to this file. This script should be able to be rerun multiple times safely.

# Install app to configure VxDev
sudo mkdir -p /vx/scripts
sudo mkdir -p /home/vx/.icons

# Copy icons and assets into the appropriate locations
sudo cp vxdev/updatecode.png /home/vx/.icons
sudo cp vxdev/configurevxdev.png /home/vx/.icons
sudo cp vxdev/runprogram.png /home/vx/.icons
sudo cp vxdev/votingworks-desktop.png /vx/.

# Copy scripts and desktop files into the appropriate places
sudo cp vxdev/update-code.sh /vx/scripts/.
sudo cp vxdev/update-vxdev.sh /vx/scripts/.
sudo cp vxdev/update-code.desktop /usr/share/applications/.
sudo cp vxdev/update-vxdev.desktop /usr/share/applications/.

# Set desktop background
gsettings set org.gnome.desktop.background picture-uri file:///vx/votingworks-desktop.png
# Set favorite apps
gsettings set org.gnome.shell favorite-apps "['update-vxdev.desktop', 'org.gnome.Screenshot.desktop', 'firefox-esr.desktop', 'org.gnome.Nautilus.desktop', 'kazam.deskptop']"
# Disable lock screen
gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'

# Lock the kernel to a specific version, upgrades require testing and upgrading wifi drivers
sudo cp vxdev/kernel /etc/apt/preferences.d/.

sudo cp vxdev/default-env /vx/config/.env.local
