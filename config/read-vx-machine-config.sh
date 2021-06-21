# This file only makes sense as a `source` target, so it isn't executable.

: "${VX_CONFIG_ROOT:="/vx/config"}"

if [ ! -f "${VX_CONFIG_ROOT}/machine-id" ]; then
  echo "expected 'machine-id' file in ${VX_CONFIG_ROOT} but it could not be found" >&2
  exit 1
fi

if [ ! -f "${VX_CONFIG_ROOT}/machine-type" ]; then
  echo "expected 'machine-type' file in ${VX_CONFIG_ROOT} but it could not be found" >&2
  exit 1
fi

if [ ! -f "${VX_CONFIG_ROOT}/code-version" ]; then
  echo "expected 'code-version' file in ${VX_CONFIG_ROOT} but it could not be found" >&2
  exit 1
fi

if [ ! -f "${VX_CONFIG_ROOT}/code-tag" ]; then
  echo "expected 'code-tag' file in ${VX_CONFIG_ROOT} but it could not be found" >&2
  exit 1
fi

export VX_MACHINE_ID="$(< "${VX_CONFIG_ROOT}/machine-id")"
export VX_MACHINE_TYPE="$(< "${VX_CONFIG_ROOT}/machine-type")"
export VX_CODE_VERSION="$(< "${VX_CONFIG_ROOT}/code-version")"
export VX_CODE_TAG="$(< "${VX_CONFIG_ROOT}/code-tag")"

if [ -f "${VX_CONFIG_ROOT}/app-mode" ]; then
  export VX_APP_MODE="$(< "${VX_CONFIG_ROOT}/app-mode")"
fi
