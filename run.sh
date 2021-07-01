#!/usr/bin/env bash

###
# run.sh – Run apps for testing purposes.
#
# This script is not used for running apps in production, but for running them
# on a device that is not yet locked down. This may be useful as a demo machine
# or for testing new builds/features/etc.
###

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ALL_APPS=()

for app in ${DIR}/vxsuite/apps/*; do
  if [[ -d "${app}" && "${app}" != */module-* ]]; then
    ALL_APPS+=("$(basename "${app}")")
  fi
done

usage() {
  echo "usage: ./run.sh ($(IFS=\| ; echo "${ALL_APPS[*]}"))"
  echo
  echo "Runs a VxSuite application for testing purposes."
}

if [ $# = 0 ]; then
  usage >&2
  exit 1
fi

APP="$1"
if [[ " ${ALL_APPS[@]} " =~ " ${APP} " ]]; then
  if [ ! -d "${DIR}/build/${APP}" ]; then
    echo "⁉️ ${APP} is not yet built, building…"
    "${DIR}/build.sh" "${APP}"
  fi

  # set up config
  export VX_CONFIG_ROOT="${DIR}/config"
  [ -f "${VX_CONFIG_ROOT}/machine-id" ] || echo 0000 > "${VX_CONFIG_ROOT}/machine-id" 
  echo "${APP}" > "${VX_CONFIG_ROOT}/machine-type" 
  [ -f "${VX_CONFIG_ROOT}/code-version" ] || echo dev > "${VX_CONFIG_ROOT}/code-version" 
  [ -f "${VX_CONFIG_ROOT}/code-tag" ] || echo dev > "${VX_CONFIG_ROOT}/code-tag" 

  export DISPLAY=:0
  cd "${DIR}/build/${APP}"
  (trap 'kill 0' SIGINT SIGHUP; "./run-${APP}.sh" & ("./run-kiosk-browser.sh"; kill 0))
elif [[ "${APP}" = -h || "${APP}" = --help ]]; then
  usage
  exit 0
else
  echo "✘ unknown app: ${APP}" >&2
  usage >&2
  exit 1
fi
