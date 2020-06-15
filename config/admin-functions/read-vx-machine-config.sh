# This file only makes sense as a `source` target, so it isn't executable.

: "${VX_CONFIG_ROOT:="${HOME}/.config"}"

export VX_MACHINE_ID="$(< "${VX_CONFIG_ROOT}/machine-id")"
export VX_MACHINE_TYPE="$(< "${VX_CONFIG_ROOT}/machine-type")"

if [ -f "${VX_CONFIG_ROOT}/app-mode" ]; then
  export VX_APP_MODE="$(< "${VX_CONFIG_ROOT}/app-mode")"
fi
