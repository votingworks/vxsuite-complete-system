#!/bin/bash


: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_METADATA_ROOT:="/vx/code"}"
APP_TYPE=$(sudo cat "$VX_CONFIG_ROOT/machine-type")

cd /vx/code/vxsuite-complete-system
git checkout main > /dev/null 2>&1
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
sudo apt remove -y nodejs # this will get reinstalled, the version could change based on what branch of the code we are building

if [[ $BRANCH == 'latest' ]]; then
	cd vxsuite
	git checkout main
	git pull
	./script/setup-dev
	cd ../kiosk-browser
	git checkout main
	git pull
	cd ..
elif [[ $BRANCH == 'stable' ]]; then
	git checkout $LATEST_TAG
	git submodule foreach --recursive sudo git clean -xfd
	git submodule update --init --recursive
	cd vxsuite
	./script/setup-dev
	cd ..
fi
cp /vx/config/.env.local vxsuite/.env.local

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
