#!/usr/bin/env bash

###
# run.sh – Run frontends for testing purposes.
#
# This script is not used for running frontends in production, but for running
# them on a device that is not yet locked down. This may be useful as a demo
# machine or for testing new builds/features/etc.
###

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Support our new /apps directory structure
ALL_APPS=()

for app in ${DIR}/vxsuite/apps/*; do
  if [ -d "${app}" ]; then
    ALL_APPS+=("$(basename "${app}")")
  fi
done

# Support our old /frontends and /services directory structure
ALL_FRONTENDS=()

for app in ${DIR}/vxsuite/frontends/*; do
  if [[ -d "${app}" ]]; then
    ALL_FRONTENDS+=("$(basename "${app}")")
  fi
done

ALL_APPS_AND_FRONTENDS=(${ALL_APPS[@]} ${ALL_FRONTENDS[@]})

usage() {
  echo "usage: ./run.sh ($(IFS=\| ; echo "${ALL_APPS_AND_FRONTENDS[*]}"))"
  echo
  echo "Runs a VxSuite app for testing purposes."
}

if [ $# = 0 ]; then
  usage >&2
  exit 1
fi

APP="$1"
if [[ " ${ALL_APPS_AND_FRONTENDS[@]} " =~ " ${APP} " ]]; then
  if [ ! -d "${DIR}/build/${APP}" ]; then
    echo "⁉️ ${APP} is not yet built, building…"
    "${DIR}/build.sh" "${APP}"
  fi

  # set up config
  export VX_CONFIG_ROOT="${DIR}/config"
  export VX_METADATA_ROOT="${DIR}"
  [ -f "${VX_CONFIG_ROOT}/machine-id" ] || echo 0000 > "${VX_CONFIG_ROOT}/machine-id" 
  echo "${APP}" > "${VX_CONFIG_ROOT}/machine-type"
  echo "VotingWorks" > "${VX_CONFIG_ROOT}/machine-manufacturer"
  [ -f "${VX_CONFIG_ROOT}/machine-model-name" ] || echo dev > "${VX_CONFIG_ROOT}/machine-model-name" 
  [ -f "${VX_METADATA_ROOT}/code-version" ] || echo dev > "${VX_METADATA_ROOT}/code-version" 
  [ -f "${VX_METADATA_ROOT}/code-tag" ] || echo dev > "${VX_METADATA_ROOT}/code-tag" 

  export DISPLAY=${DISPLAY:-:0}
  cd "${DIR}/build/${APP}"
  (trap 'kill 0' SIGINT SIGHUP; "./run-${APP}.sh" & ("./run-kiosk-browser.sh"; kill 0)) 2>&1 | logger --tag votingworksapp
elif [[ "${APP}" = -h || "${APP}" = --help ]]; then
  usage
  exit 0
else
  echo "✘ unknown app: ${APP}" >&2
  usage >&2
  exit 1
fi
