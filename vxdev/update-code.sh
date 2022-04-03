#!/bin/bash


: "${VX_CONFIG_ROOT:="/vx/config"}"
APP_TYPE=$(sudo cat "$VX_CONFIG_ROOT/machine-type")

cd /vx/code/vxsuite-complete-system
git checkout main > /dev/null
git pull > /dev/null
git fetch --tags > /dev/null
sudo git clean -xfd > /dev/null
git submodule foreach --recursive sudo git clean -xfd > /dev/null
LATEST_TAG=$(git describe --tags `git rev-list --tags --max-count=1`)

CHOICES=('')
echo "What code version would you like to update to?"

echo "${#CHOICES[@]}. Latest Code"
CHOICES+=('latest')

echo "2. Latest Stable Release ($LATEST_TAG)"
CHOICES+=('stable')

echo
read -p "Select Option: " CHOICE_INDEX

if [ "${CHOICE_INDEX}" -ge "${#CHOICES[@]}" ] || [ "${CHOICE_INDEX}" -lt 1 ]
then
    echo "You need to select a valid option."
    exit 1
fi
BRANCH=${CHOICES[$CHOICE_INDEX]}

if [[ $BRANCH == 'latest' ]]; then
	cd vxsuite
	git checkout main
	git pull
	cd ../kiosk-browser
	git checkout main
	git pull
	cd ..
elif [[ $BRANCH == 'stable' ]]; then
	git checkout $LATEST_TAG
	git submodule foreach --recursive sudo git clean -xfd
	git submodule update --init --recursive
fi

make build-kiosk-browser
echo $APP_TYPE
if [[ $APP_TYPE == 'VxCentralScan' ]] || [[ $APP_TYPE == 'VxAdminCentralScan' ]]; then
	./build.sh bsd
fi
if [[ $APP_TYPE == 'VxAdmin' ]] || [[ $APP_TYPE == 'VxAdminCentralScan' ]]; then
	./build.sh election-manager
fi
if [[ $APP_TYPE == 'VxMark' ]]; then
	./build.sh bmd
fi
if [[ $APP_TYPE == 'VxScan' ]]; then
	./build.sh precinct-scanner
fi

echo "Done! Closing in 3 seconds."
