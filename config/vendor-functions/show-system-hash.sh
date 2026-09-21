#!/bin/bash

trap '' SIGINT SIGTSTP SIGQUIT

set -euo pipefail

: "${VX_METADATA_ROOT:="/vx/code"}"
: "${VXSUITE_ROOT:="${VX_METADATA_ROOT}/vxsuite"}"

"${VXSUITE_ROOT}/libs/auth/src/intermediate-scripts/compute-system-hash"
read -p "Press enter once you have recorded the system hash. "
