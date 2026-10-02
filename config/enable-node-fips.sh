#!/usr/bin/env bash

: "${VX_CONFIG_ROOT:="/vx/config"}"

NODE_FIPS_OPENSSL_CONFIG="${VX_CONFIG_ROOT}/openssl.cnf"
NODE_FIPS_MODULE_CONFIG="${VX_CONFIG_ROOT}/fipsmodule.cnf"
NODE_FIPS_MODULES_DIR="$(openssl version -m | sed -E 's/^MODULESDIR: "(.*)"$/\1/')"

if [ -f "${NODE_FIPS_OPENSSL_CONFIG}" ] && [ -f "${NODE_FIPS_MODULE_CONFIG}" ] && [ -f "${NODE_FIPS_MODULES_DIR}/fips.so" ]; then
  export OPENSSL_CONF="${NODE_FIPS_OPENSSL_CONFIG}"
  export OPENSSL_MODULES="${NODE_FIPS_MODULES_DIR}"
  export NODE_OPTIONS="--force-fips=strict --openssl-shared-config"
else
  echo "There is no FIPS configuration available. Node is running in non-compliant mode." >&2
fi
