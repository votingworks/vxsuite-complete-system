#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "usage: setup-app.sh TYPE -o PATH"
  echo
  echo "setup-app.sh bmd -o /vx/code"
  echo "setup-app.sh election-manager -o build"
}

# Where to put the app.
VX_OUT=
# Which app to setup.
VX_MACHINE_TYPE=

while [ $# -gt 0 ]; do
  arg="$1"
  case "${arg}" in
    -h|--help)
      usage
      exit 0
    ;;

    -o|--output)
      shift
      VX_OUT="$1"
      if [[ "${VX_OUT}" = -* ]]; then
        echo "error: expected path after ${arg}, got '${VX_OUT}'" >&2
        usage >&2
        exit 1
      fi
    ;;

    *)
      if [ -n "${VX_MACHINE_TYPE}" ]; then
        echo "error: unexpected argument '${arg}'" >&2
        usage >&2
        exit 1
      fi

      VX_MACHINE_TYPE="${arg}"
    ;;
  esac
  shift
done

if [ -z "${VX_OUT}" ]; then
  echo "error: required --output PATH is missing" >&2
  usage >&2
  exit 1
fi

if [ -z "${VX_MACHINE_TYPE}" ]; then
  echo "error: required TYPE is missing" >&2
  usage >&2
  exit 1
fi

mkdir -p "${VX_OUT}/vxsuite/apps"

case "${VX_MACHINE_TYPE}" in
  bas)
    cp -rp vxsuite/build/apps/bas \
          vxsuite/build/apps/module-smartcards \
          "${VX_OUT}/vxsuite/apps"
  ;;

  bmd)
    cp -rp vxsuite/build/apps/bmd \
          vxsuite/build/apps/module-smartcards \
          "${VX_OUT}/vxsuite/apps"
  ;;

  election-manager)
    cp -rp vxsuite/build/apps/election-manager \
          vxsuite/build/apps/module-smartcards \
          "${VX_OUT}/vxsuite/apps"
  ;;

  bsd)
    cp -rp vxsuite/build/apps/bsd \
          vxsuite/build/apps/module-scan \
          "${VX_OUT}/vxsuite/apps"
    cp -rp vxsuite/build/libs \
          "${VX_OUT}/vxsuite"
  ;;

  precinct-scanner)
    cp -rp vxsuite/build/apps/precinct-scanner \
          vxsuite/build/apps/module-scan \
          vxsuite/build/apps/module-smartcards \
          "${VX_OUT}/vxsuite/apps"
    cp -rp vxsuite/build/libs \
          "${VX_OUT}/vxsuite"
  ;;

  *)
    echo "error: unsupported type: '${VX_MACHINE_TYPE}'" >&2
    usage >&2
    exit 1
  ;;
esac

cp -rp run-${VX_MACHINE_TYPE}.sh \
       run-kiosk-browser*.sh \
       config \
       printing \
       "${VX_OUT}"

cp -rp vxsuite/build/node_modules \
       vxsuite/build/pnpm-lock.yaml \
       vxsuite/build/pnpm-workspace.yaml \
       vxsuite/build/pnpmfile.js \
       vxsuite/build/package.json \
       "${VX_OUT}/vxsuite"

pnpm --dir "${VX_OUT}/vxsuite" install
