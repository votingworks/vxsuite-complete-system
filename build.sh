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

ALL_FRONTENDS=()
ALL_SERVICES=()

for app in ${DIR}/vxsuite/frontends/*; do
  if [ -d "${app}" ]; then
    ALL_FRONTENDS+=("$(basename "${app}")")
  fi
done

for app in ${DIR}/vxsuite/services/*; do
  if [ -d "${app}" ]; then
    ALL_SERVICES+=("$(basename "${app}")")
  fi
done

usage() {
  echo "usage: ./build.sh [all|$(IFS=\| ; echo "${ALL_FRONTENDS[*]}")] …"
  echo
  echo "Build all or some of the VxSuite frontends."
}

build() {
  local APP="$1"
  echo "🔨Building ${APP}"
  export BUILD_ROOT="${DIR}/build/${APP}"
  rm -rf "${BUILD_ROOT}"
  (
    for service in "${ALL_SERVICES[@]}"; do
      make -C "${DIR}/vxsuite/services/${service}" install
    done
    for frontend in "${ALL_FRONTENDS[@]}"; do
      make -C "${DIR}/vxsuite/frontends/${frontend}" install
    done

    cd "${DIR}/vxsuite/frontends/${APP}"
    pnpm install
    BUILD_ROOT="${BUILD_ROOT}/vxsuite" ./script/prod-build

    cp -rp \
      "${DIR}/run-scripts/run-${APP}.sh" \
      "${DIR}/run-scripts/run-kiosk-browser.sh" \
      "${DIR}/run-scripts/run-kiosk-browser-forever-and-log.sh" \
      "${DIR}/config" \
      "${DIR}/printing" \
      "${BUILD_ROOT}"

    # temporary hack because the symlink works but somehow the copy doesn't for precinct-scanner
    cd ${BUILD_ROOT}
    rm -rf vxsuite # this is the built version
    ln -s ../../vxsuite ./vxsuite
  ) && \
  echo "✅${APP} built!" || \
  (echo "✘ ${APP} build failed! check the logs above" >&2 && exit 1)
}

APPS=()

if [ $# = 0 ]; then
  APPS+=(${ALL_FRONTENDS[@]})
else
  for arg in $@; do
    if [[ " ${ALL_FRONTENDS[@]} " =~ " ${arg} " ]]; then
      if [[ ! " ${APPS[@]} " =~ " ${arg} " ]]; then
        APPS+=($arg)
      fi
    elif [[ "${arg}" = all ]]; then
      APPS=(${ALL_FRONTENDS[@]})
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
