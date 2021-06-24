#!/usr/bin/env bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

usage() {
  echo "usage: ./build.sh (all|bas|bmd|bsd|election-manager|precinct-scanner)"
}

if [ $# = 0 ]; then
  usage >&2
  exit 1
fi

ALL_MODULES=(module-converter-ms-sems module-scan module-smartcards)
ALL_APPS=(bas bmd bsd election-manager precinct-scanner)

build() {
  local APP="$1"
  export BUILD_ROOT="${DIR}/build/${APP}"
  rm -rf "${BUILD_ROOT}"
  (
    #
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

APP="$1"
if [ "${APP}" = all ]; then
  for app in "${ALL_APPS[@]}"; do
    build "${app}"
  done
elif [[ " ${ALL_APPS[@]} " =~ " ${APP} " ]]; then
  build "${APP}"
else
  echo "✘ unknown app: ${APP}" >&2
  usage >&2
  exit 1
fi
