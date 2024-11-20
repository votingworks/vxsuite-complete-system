#!/usr/bin/env bash

# Requires sudo

set -euo pipefail

if [ ! -f /usr/local/ssl/fipsmodule.cnf ]; then
  echo "There is no FIPS configuration available. Running in non-compliant mode."
  exit 0
else
  echo "Installing and verifying FIPS configuration."
  cp /usr/local/ssl/fipsmodule.cnf /vx/config/fipsmodule.cnf
  openssl fipsinstall -out /vx/config/fipsmodule.cnf -module /lib/x86_64-linux-gnu/ossl-modules/fips.so
fi

exit 0
