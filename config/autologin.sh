#!/bin/bash

# This script is designed to be run in override.conf file for the service getty@tty1.
# It conditionally selects which user to autologin based on whether or not the
# machine needs configuration.
if [[ -f /vx/config/RUN_BASIC_CONFIGURATION_ON_NEXT_BOOT ]]; then
    USER=vx-admin
else
    USER=vx-ui
fi
# For the getty service, you can't have any nested processes, thus we use exec to
# make mingetty take over the process of this script.
exec /sbin/mingetty --autologin $USER --noclear $1
