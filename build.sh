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
#   ./run.sh bmd
#
# This will leave the machine in an unlocked, unspecialized state suitable for
# testing out new builds/features/etc.
###

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ALL_APPS=()
ALL_MODULES=()

for app in ${DIR}/vxsuite/apps/*; do
  if [ -d "${app}" ]; then
    if [[ "${app}" = */module-* ]]; then
      ALL_MODULES+=("$(basename "${app}")")
    else
      ALL_APPS+=("$(basename "${app}")")
    fi
  fi
done

usage() {
  echo "usage: ./build.sh [all|$(IFS=\| ; echo "${ALL_APPS[*]}")] …"
  echo
  echo "Build all or some of the VxSuite applications."
}

build() {
  local APP="$1"
  echo "🔨Building ${APP}"
  export BUILD_ROOT="${DIR}/build/${APP}"
  rm -rf "${BUILD_ROOT}"
  (
    for app in "${ALL_APPS[@]}" "${ALL_MODULES[@]}"; do
      make -C "${DIR}/vxsuite/apps/${app}" install
    done

    cd "${DIR}/vxsuite/apps/${APP}"
    pnpm install
    BUILD_ROOT="${BUILD_ROOT}/vxsuite" ./script/prod-build
    cp -rp \
      "${DIR}/run-scripts/run-${APP}.sh" \
      "${DIR}/run-scripts/run-kiosk-browser.sh" \
      "${DIR}/run-scripts/run-kiosk-browser-forever-and-log.sh" \
      "${DIR}/config" \
      "${DIR}/printing" \
      "${BUILD_ROOT}"
  ) && \
  echo "✅${APP} built!" || \
  (echo "✘ ${APP} build failed! check the logs above" >&2 && exit 1)
}

APPS=()

if [ $# = 0 ]; then
  APPS+=(${ALL_APPS[@]})
else
  for arg in $@; do
    if [[ " ${ALL_APPS[@]} " =~ " ${arg} " ]]; then
      if [[ ! " ${APPS[@]} " =~ " ${arg} " ]]; then
        APPS+=($arg)
      fi
    elif [[ "${arg}" = all ]]; then
      APPS=(${ALL_APPS[@]})
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

echo "Building ${#APPS[@]} app(s): ${APPS[@]}"
for app in "${APPS[@]}"; do
  build "${app}"
done
