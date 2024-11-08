#!/bin/bash

set -euo pipefail

: "${VX_METADATA_ROOT:="/vx/code"}"

"${VX_METADATA_ROOT}/vxsuite/libs/auth/src/intermediate-scripts/compute-system-hash"
read -p "Press enter once you have recorded the system hash. "
