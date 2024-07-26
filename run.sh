#!/usr/bin/env bash

###
# run.sh – Run apps for testing purposes.
#
# This script is not used for running apps in production, but for running
# them on a device that is not yet locked down. This may be useful as a demo
# machine or for testing new builds/features/etc.
###

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ALL_APPS=()

for app in ${DIR}/vxsuite/apps/*; do
  if [ -d "${app}" ]; then
    ALL_APPS+=("$(basename "${app}")")
  fi
done


usage() {
  echo "usage: ./run.sh ($(IFS=\| ; echo "${ALL_APPS[*]}"))"
  echo
  echo "Runs a VxSuite app for testing purposes."
}

if [ $# = 0 ]; then
  usage >&2
  exit 1
fi

APP="$1"
if [[ " ${ALL_APPS[@]} " =~ " ${APP} " ]]; then
  if [ ! -d "${DIR}/build/${APP}" ]; then
    echo "⁉️ ${APP} is not yet built, building…"
    "${DIR}/prepare_build.sh" "${APP}"
    "${DIR}/build.sh" "${APP}"
  fi

  # set up config
  export VX_CONFIG_ROOT="${DIR}/config"
  export VX_METADATA_ROOT="${DIR}"
  [ -f "${VX_CONFIG_ROOT}/machine-id" ] || echo 0000 > "${VX_CONFIG_ROOT}/machine-id" 
  echo "${APP}" > "${VX_CONFIG_ROOT}/machine-type"
  echo "VotingWorks" > "${VX_CONFIG_ROOT}/machine-manufacturer"
  echo "1" > "${VX_CONFIG_ROOT}/is-qa-image"
  [ -f "${VX_CONFIG_ROOT}/machine-model-name" ] || echo dev > "${VX_CONFIG_ROOT}/machine-model-name" 
  [ -f "${VX_METADATA_ROOT}/code-version" ] || echo dev > "${VX_METADATA_ROOT}/code-version" 
  [ -f "${VX_METADATA_ROOT}/code-tag" ] || echo dev > "${VX_METADATA_ROOT}/code-tag" 

  # mark-scan requires daemons running in the background
  # reload their daemon configs and then issue restart commands
  if [[ "${APP}" == "mark-scan" ]]; then
    sudo systemctl daemon-reload
    for vx_daemon in controller pat fai-100
    do
      sudo systemctl restart mark-scan-${vx_daemon}-daemon.service
    done
  fi
  export DISPLAY=${DISPLAY:-:0}
  cd "${DIR}/build/${APP}"
  (
    trap 'kill 0' SIGINT SIGHUP; "./run-${APP}.sh" &
    # Delay kiosk-browser to make sure the app is running first
    (while ! curl -s localhost:3000; do sleep 1; done; "./run-kiosk-browser.sh"; kill 0)
  ) 2>&1 | logger --tag votingworksapp
elif [[ "${APP}" = -h || "${APP}" = --help ]]; then
  usage
  exit 0
else
  echo "✘ unknown app: ${APP}" >&2
  usage >&2
  exit 1
fi
