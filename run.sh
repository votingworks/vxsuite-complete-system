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

ALL_FRONTENDS=()

for app in ${DIR}/vxsuite/frontends/*; do
  if [[ -d "${app}" ]]; then
    ALL_FRONTENDS+=("$(basename "${app}")")
  fi
done

usage() {
  echo "usage: ./run.sh ($(IFS=\| ; echo "${ALL_FRONTENDS[*]}"))"
  echo
  echo "Runs a VxSuite frontend for testing purposes."
}

if [ $# = 0 ]; then
  usage >&2
  exit 1
fi

FRONTEND="$1"
if [[ " ${ALL_FRONTENDS[@]} " =~ " ${FRONTEND} " ]]; then
  if [ ! -d "${DIR}/build/${FRONTEND}" ]; then
    echo "⁉️ ${FRONTEND} is not yet built, building…"
    "${DIR}/build.sh" "${FRONTEND}"
  fi

  # set up config
  export VX_CONFIG_ROOT="${DIR}/config"
  [ -f "${VX_CONFIG_ROOT}/machine-id" ] || echo 0000 > "${VX_CONFIG_ROOT}/machine-id" 
  echo "${FRONTEND}" > "${VX_CONFIG_ROOT}/machine-type" 
  echo "VotingWorks" > "${VX_CONFIG_ROOT}/machine-manufacturer"
  [ -f "${VX_CONFIG_ROOT}/machine-model-name" ] || echo dev > "${VX_CONFIG_ROOT}/machine-model-name" 
  [ -f "${VX_CONFIG_ROOT}/code-version" ] || echo dev > "${VX_CONFIG_ROOT}/code-version" 
  [ -f "${VX_CONFIG_ROOT}/code-tag" ] || echo dev > "${VX_CONFIG_ROOT}/code-tag" 

  export DISPLAY=:0
  cd "${DIR}/build/${FRONTEND}"
  (trap 'kill 0' SIGINT SIGHUP; "./run-${FRONTEND}.sh" & ("./run-kiosk-browser.sh"; kill 0)) | logger --tag votingworksapp
elif [[ "${FRONTEND}" = -h || "${FRONTEND}" = --help ]]; then
  usage
  exit 0
else
  echo "✘ unknown frontend: ${FRONTEND}" >&2
  usage >&2
  exit 1
fi
