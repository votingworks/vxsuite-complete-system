#!/usr/bin/env bash

###
# build.sh – Build apps for testing or production.
#
# This script builds one or all of the VxSuite applications. It is used by
# setup-machine.sh when a machine becomes specialized and locked down.
#
# To keep the machine able to switch between apps for testing purposes, run:
#
#   ./build.sh all
#
# Then, you can run a specific app for testing like so:
#
#   ./run.sh mark
#
# This will leave the machine in an unlocked, unspecialized state suitable for
# testing out new builds/features/etc.
###

set -euo pipefail

local_user=$(logname)
local_user_home_dir=$( getent passwd "${local_user}" | cut -d: -f6 )

# Make sure PATH includes cargo and /sbin
export PATH="${local_user_home_dir}/.cargo/bin:${PATH}:/sbin/"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Define vxsuite apps that can be built, along with the expected path prefix
ALL_APPS=(admin central-scan mark mark-scan print scan)
# shellcheck disable=SC2034
APPS_PATH_PREFIX="${DIR}/vxsuite/apps"

# Define vxsuite services that can be built, along with the expected path prefix
# shellcheck disable=SC2034
ALL_SERVICES=(converter-ms-sems)
# shellcheck disable=SC2034
SERVICES_PATH_PREFIX="${DIR}/vxsuite/services"

usage() {
  echo "usage: ./prepare_build.sh [all|$(IFS=\| ; echo "${ALL_APPS[*]}")]"
  echo
  echo "Prepare to build all or some of the VxSuite apps."
}

APPS_TO_BUILD=()

# Determine which apps to build
if [ $# = 0 ]; then
  # shellcheck disable=SC2206
  APPS_TO_BUILD+=(${ALL_APPS[@]})
else
  # shellcheck disable=SC2068
  for arg in $@; do
    # shellcheck disable=SC2199,SC2076
    if [[ " ${ALL_APPS[@]} " =~ " ${arg} " ]]; then
      # shellcheck disable=SC2199,SC2076
      if [[ ! " ${APPS_TO_BUILD[@]} " =~ " ${arg} " ]]; then
        # shellcheck disable=SC2206
        APPS_TO_BUILD+=($arg)
      fi
    elif [[ "${arg}" = all ]]; then
      # shellcheck disable=SC2206
      APPS_TO_BUILD=(${ALL_APPS[@]})
    elif [[ "${arg}" = -h || "${arg}" = --help ]]; then
      usage
      exit 0
    elif [[ "${arg}" = -* ]]; then
      echo "✘ unknown option: ${arg}" >&2
      usage >&2
      exit 1
    else
      echo "✘ unknown app: ${arg}" >&2
      usage >&2
      exit 1
    fi
  done
fi

# Function that builds a single app
build() {
  local APP="$1"
  echo "🔨Preparing ${APP} for build"
  export BUILD_ROOT="${DIR}/build/${APP}"
  rm -rf "${BUILD_ROOT}"
  # In order to get the subshell exit code without exiting the whole script, we
  # need to temporarily set +e
  set +e
  # shellcheck disable=SC2015
  (
    set -euo pipefail

    cd "${DIR}/vxsuite/apps/${APP}/frontend"

    pnpm install --frozen-lockfile
  ) && {
    echo -e "\e[32m✅${APP} ready for building\e[0m"
  } || {
    echo -e "\e[31m✘ ${APP} build prep failed! check the logs above\e[0m" >&2
    exit 1
  }
  set -e
}

echo "Download all Rust crates"
pnpm --recursive install:rust-addon

if ! which kiosk-browser >/dev/null 2>&1
then
  echo "Download all kiosk-browser tools"
  make -C kiosk-browser install
fi

# shellcheck disable=SC2145
echo "Preparing ${#APPS_TO_BUILD[@]} app(s): ${APPS_TO_BUILD[@]}"

for app in "${APPS_TO_BUILD[@]}"; do
  build "${app}"
  # mark-scan has additional daemons that need to be built
  # so we fetch their Rust crates while online
  if [[ "${app}" == "mark-scan" ]]; then
    # default to 155 daemons
    vx_daemons="accessible-controller pat-device-input"
    vxsuite_env_file="${DIR}/vxsuite/.env"

    # check for the 150 env var to build the 150 daemon instead
    if grep REACT_APP_VX_MARK_SCAN_USE_BMD_150 "$vxsuite_env_file" | grep -i true > /dev/null 2>&1
    then
      vx_daemons="fai-100-controller"
    fi

    for vx_daemon in ${vx_daemons}
    do
      cd "${DIR}/vxsuite/apps/mark-scan/${vx_daemon}"
      cargo fetch
    done
  fi
done

exit 0
