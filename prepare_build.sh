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

local_user=`logname`
local_user_home_dir=$( getent passwd "${local_user}" | cut -d: -f6 )

# Make sure PATH includes cargo and /sbin
export PATH="${local_user_home_dir}/.cargo/bin:${PATH}:/sbin/"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Define vxsuite apps that can be built, along with the expected path prefix
ALL_APPS=(admin central-scan mark scan mark-scan)
APPS_PATH_PREFIX="${DIR}/vxsuite/apps"

# Define vxsuite services that can be built, along with the expected path prefix
ALL_SERVICES=(converter-ms-sems)
SERVICES_PATH_PREFIX="${DIR}/vxsuite/services"

usage() {
  echo "usage: ./prepare_build.sh [all|$(IFS=\| ; echo "${ALL_APPS[*]}")]"
  echo
  echo "Prepare to build all or some of the VxSuite apps."
}

APPS_TO_BUILD=()

# Determine which apps to build
if [ $# = 0 ]; then
  APPS_TO_BUILD+=(${ALL_APPS[@]})
else
  for arg in $@; do
    if [[ " ${ALL_APPS[@]} " =~ " ${arg} " ]]; then
      if [[ ! " ${APPS_TO_BUILD[@]} " =~ " ${arg} " ]]; then
        APPS_TO_BUILD+=($arg)
      fi
    elif [[ "${arg}" = all ]]; then
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
  (
    set -euo pipefail

    cd "${DIR}/vxsuite/apps/${APP}/frontend"

    pnpm install --frozen-lockfile
  )
  if [[ $? = 0 ]]; then
    echo -e "\e[32m✅${APP} ready for building\e[0m"
  else
    echo -e "\e[31m✘ ${APP} build prep failed! check the logs above\e[0m" >&2
    exit 1
  fi
  set -e
}

echo "Download all Rust crates"
pnpm --recursive install:rust-addon

echo "Download all kiosk-browser tools"
make -C kiosk-browser install

echo "Preparing ${#APPS_TO_BUILD[@]} app(s): ${APPS_TO_BUILD[@]}"

for app in "${APPS_TO_BUILD[@]}"; do
  build "${app}"
  if [[ "${app}" == "mark-scan" ]]; then
    make -C "${DIR}/vxsuite/apps/mark-scan/accessible-controller" build
    make -C "${DIR}/vxsuite/apps/mark-scan/pat-device-input" build
  fi
done

exit 0
