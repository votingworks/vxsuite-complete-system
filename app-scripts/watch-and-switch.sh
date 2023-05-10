#!/bin/bash
#
# This script watches for signals in /tmp to switch the app and takes appropriate action.
# We do it this way because a particular app turning itself off is tricky to pull off,
# so we use a file signal to have a separate process do it.
#

SWITCH_TO_ADMIN="/tmp/SWITCH_TO_ADMIN"
SWITCH_TO_CENTRALSCAN="/tmp/SWITCH_TO_CENTRALSCAN"

while true; do
    sleep 1
    
    if test -f "$SWITCH_TO_ADMIN"; then
	rm $SWITCH_TO_ADMIN
	sudo /vx/code/app-scripts/switch-to-admin.sh
    fi
    
    if test -f "$SWITCH_TO_CENTRALSCAN"; then
	rm $SWITCH_TO_CENTRALSCAN
	sudo /vx/code/app-scripts/switch-to-centralscan.sh
    fi
done
