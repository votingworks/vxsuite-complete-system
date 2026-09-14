#!/bin/bash


: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_METADATA_ROOT:="/vx/code"}"
APP_TYPE=$(sudo cat "$VX_CONFIG_ROOT/machine-type")

local_user=`logname`
local_user_home_dir=$( getent passwd "${local_user}" | cut -d: -f6 )
code_dir="${local_user_home_dir}/code"
kiosk_browser_dir="${local_user_home_dir}/code/kiosk-browser"
complete_system_dir="${local_user_home_dir}/code/vxsuite-complete-system"
vxsuite_dir="${local_user_home_dir}/code/vxsuite"
build_system_dir="${local_user_home_dir}/code/vxsuite-build-system"

pushd ${build_system_dir}
git checkout main > /dev/null 2>&1
git pull > /dev/null 2>&1
git fetch --tags > /dev/null 2>&1
sudo git clean -dfx > /dev/null 2>&1
LATEST_STABLE=$( git describe --tags `git rev-list --tags --max-count=1` )
popd

CHOICES=('')
echo "What code version would you like to update to?"

echo "${#CHOICES[@]}. Latest Code"
CHOICES+=('latest')

echo "2. Latest Stable Release ($LATEST_STABLE)"
CHOICES+=('stable')

echo "3. Custom Branches"
CHOICES+=('custom')

echo
read -p "Select Option: " CHOICE_INDEX

if [ "${CHOICE_INDEX}" -ge "${#CHOICES[@]}" ] || [ "${CHOICE_INDEX}" -lt 1 ]
then
    echo "You need to select a valid option."
    exit 1
fi

BRANCH=${CHOICES[$CHOICE_INDEX]}

if [[ $BRANCH == 'latest' ]]; then
	for dir in ${complete_system_dir} ${vxsuite_dir} ${kiosk_browser_dir}
	do
	  pushd ${dir}
	  sudo git clean -dfx
 	  git checkout main
	  git pull
	  popd
        done
elif [[ $BRANCH == 'stable' ]]; then
	pushd ${build_system_dir}
	git checkout ${LATEST_STABLE}
	main_yaml="inventories/stable/group_vars/all/main.yaml"
	repos=$(yq -r '.repos | keys | .[]' "${main_yaml}")
	for repo in ${repos}
	do
          version=$(yq -r ".repos.\"${repo}\".version" "${main_yaml}")
	  echo "Repo: $repo --> Version: $version"
	  pushd ${code_dir}/${repo}
	  sudo git clean -dfx
          git checkout main
	  git pull
	  git checkout ${version}
	  popd
	done
	popd
elif [[ $BRANCH == 'custom' ]]; then
	for repo in vxsuite vxsuite-complete-system kiosk-browser
	do
	  read -p "Enter the ${repo} branch name: " BRANCH_NAME
	  pushd ${code_dir}/${repo}
	  sudo git clean -dfx
	  git checkout main
	  git pull
	  while [ !`git branch -r --list origin/$BRANCH_NAME` ]
	  do
	    read -p "Invalid Branch Name. Try again: " BRANCH_NAME
	  done
	  git checkout $BRANCH_NAME
	  popd
	done
fi

echo
read -p "Enable HWTA? [y/n]: " ENABLE_HWTA

if [[ "${ENABLE_HWTA}" == 'y' || "${ENABLE_HWTA}" == 'Y' ]]; then
  sudo /vx/scripts/set-hwta-env.sh yes
  sudo /vx/scripts/set-dev-dock-env.sh no
else
  sudo /vx/scripts/set-hwta-env.sh no
  read -p "Enable Dev Dock? [y/n]: " ENABLE_DEV_DOCK
  if [[ "${ENABLE_DEV_DOCK}" == 'y' || "${ENABLE_DEV_DOCK}" == 'Y' ]]; then
    sudo /vx/scripts/set-dev-dock-env.sh yes
  else
    sudo /vx/scripts/set-dev-dock-env.sh no
  fi
fi

cp /vx/config/.env.local ${vxsuite_dir}/.env.local

# improve this by tracking commit id
# only rebuild when it changes
if ! which kiosk-browser >/dev/null 2>&1
then
	make build-kiosk-browser
fi

echo $APP_TYPE
pushd ${build_system_dir}
if [[ $APP_TYPE == 'VxAdmin' ]] || [[ $APP_TYPE == 'VxAdminCentralScan' ]]; then
	cp /vx/config/.env.local ${vxsuite_dir}/apps/admin/frontend/.env.local
	cp /vx/config/.env.local ${vxsuite_dir}/apps/admin/backend/.env.local
	./scripts/tb-prepare-build.sh admin
	./scripts/tb-build.sh admin
fi
if [[ $APP_TYPE == 'VxCentralScan' ]] || [[ $APP_TYPE == 'VxAdminCentralScan' ]]; then
	cp /vx/config/.env.local ${vxsuite_dir}/apps/central-scan/backend/.env.local
	cp /vx/config/.env.local ${vxsuite_dir}/apps/central-scan/frontend/.env.local
	./scripts/tb-prepare-build.sh central-scan
	./scripts/tb-build.sh central-scan
fi
if [[ $APP_TYPE == 'VxMark' ]]; then
	cp /vx/config/.env.local ${vxsuite_dir}/apps/mark/frontend/.env.local
	cp /vx/config/.env.local ${vxsuite_dir}/apps/mark/backend/.env.local
	./scripts/tb-prepare-build.sh mark
	./scripts/tb-build.sh mark
fi
if [[ $APP_TYPE == 'VxMarkScan' ]]; then
	cp /vx/config/.env.local ${vxsuite_dir}/apps/mark-scan/backend/.env.local
	cp /vx/config/.env.local ${vxsuite_dir}/apps/mark-scan/frontend/.env.local
	./scripts/tb-prepare-build.sh mark-scan
	./scripts/tb-build.sh mark-scan
	for vx_daemon in controller pat
	do
	  pushd ${complete_system_dir}
	  sudo cp config/mark-scan-${vx_daemon}-daemon.service /etc/systemd/system/
	  sudo cp run-scripts/run-mark-scan-${vx_daemon}-daemon.sh /vx/code/
	  sudo chmod 644 /etc/systemd/system/mark-scan-${vx_daemon}-daemon.service
	  sudo ln -sf /vx/code/run-mark-scan-${vx_daemon}-daemon.sh /vx/services/run-mark-scan-${vx_daemon}-daemon.sh
	  sudo systemctl daemon-reload
	  popd
	done
fi
if [[ $APP_TYPE == 'VxPrint' ]]; then
	cp /vx/config/.env.local ${vxsuite_dir}/apps/print/backend/.env.local
	cp /vx/config/.env.local ${vxsuite_dir}/apps/print/frontend/.env.local
	./scripts/tb-prepare-build.sh print
	./scripts/tb-build.sh print
fi
if [[ $APP_TYPE == 'VxScan' ]]; then
	cp /vx/config/.env.local ${vxsuite_dir}/apps/scan/backend/.env.local
	cp /vx/config/.env.local ${vxsuite_dir}/apps/scan/frontend/.env.local
	./scripts/tb-prepare-build.sh scan
	./scripts/tb-build.sh scan
fi
popd

echo "Done! Closing in 3 seconds."
