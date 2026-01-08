#!/bin/bash

# This script is designed to be run in override.conf file for the service getty@tty1.
# It conditionally selects which user to automatically log in as, based on whether or not the
# machine 1) needs configuration or 2) is being rebooted into the vendor menu.
if [[ -f /vx/config/EXPAND_VAR ]] || [[ -f /vx/config/RUN_BASIC_CONFIGURATION_ON_NEXT_BOOT ]] || [[ -f /vx/config/app-flags/REBOOT_TO_VENDOR_MENU ]]; then
    USER=vx-vendor
else
    USER=vx-ui
fi
# For the getty service, you can't have any nested processes, thus we use exec to
# make mingetty take over the process of this script.
exec /sbin/mingetty --noissue --autologin $USER --noclear "$1"
