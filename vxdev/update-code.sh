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

echo "3. Custom Branch"
CHOICES+=('custom')

echo
read -p "Select Option: " CHOICE_INDEX

if [ "${CHOICE_INDEX}" -ge "${#CHOICES[@]}" ] || [ "${CHOICE_INDEX}" -lt 1 ]
then
    echo "You need to select a valid option."
    exit 1
fi

BRANCH=${CHOICES[$CHOICE_INDEX]}
sudo apt remove -y nodejs > /dev/null # this will get reinstalled, the version could change based on what branch of the code we are building

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
elif [[ $BRANCH == 'custom' ]]; then
	read -p "Enter the branch name: " BRANCH_NAME
	cd vxsuite
	git checkout main
	git pull
	while [ !`git branch -r --list origin/$BRANCH_NAME` ]
	do
		read -p "Invalid Branch Name. Try again: " BRANCH_NAME
	done
	git checkout $BRANCH_NAME
	./script/setup-dev
	cd ../kiosk-browser
	git checkout main
	git pull
	cd ..
fi
cp /vx/config/.env.local vxsuite/.env.local

make build-kiosk-browser
echo $APP_TYPE
if [[ $APP_TYPE == 'VxCentralScan' ]] || [[ $APP_TYPE == 'VxAdminCentralScan' ]]; then
	cp /vx/config/.env.local vxsuite/services/scan/.env.local
	cp /vx/config/.env.local vxsuite/frontends/bsd/.env.local
	./build.sh bsd
fi
if [[ $APP_TYPE == 'VxAdmin' ]] || [[ $APP_TYPE == 'VxAdminCentralScan' ]]; then
	cp /vx/config/.env.local vxsuite/frontends/election-manager/.env.local
	cp /vx/config/.env.local vxsuite/services/admin/.env.local
	./build.sh election-manager
fi
if [[ $APP_TYPE == 'VxMark' ]]; then
	cp /vx/config/.env.local vxsuite/apps/mark/frontend/.env.local
	cp /vx/config/.env.local vxsuite/apps/mark/backend/.env.local
	./build.sh mark
fi
if [[ $APP_TYPE == 'VxScan' ]]; then
	cp /vx/config/.env.local vxsuite/apps/vx-scan/backend/.env.local
	cp /vx/config/.env.local vxsuite/apps/vx-scan/frontend/.env.local
	./build.sh vx-scan
fi

echo "Done! Closing in 3 seconds."
