#!/bin/bash

: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_METADATA_ROOT:="/vx/code"}"

#cd ~/vx/code/vxsuite-complete-system
BRANCH="$1"

if [[ $BRANCH == 'latest' ]]; then
	cd vxsuite
 	git checkout main
	git pull
	cd ../kiosk-browser
	git checkout main
	git pull
	cd ..
elif [[ $BRANCH == 'stable' ]]; then
	TAG="$2"
	git checkout $TAG
	git submodule update --init --recursive
elif [[ $BRANCH == 'custom' ]]; then
	CUSTOM_BRANCH="$2"
	cd vxsuite
	git checkout main
	git pull
	if [ !`git branch -r --list origin/$CUSTOM_BRANCH` ]; then
		read -p "Invalid Branch Name. Try again: " BRANCH_NAME
		exit
	fi
	git checkout $CUSTOM_BRANCH
	cd ../kiosk-browser
	git checkout main
	git pull
	cd ..
fi
