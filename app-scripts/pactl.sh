#!/bin/bash

set -euo pipefail

usage () {
  echo "Usage: pactl <options>"
  exit 1
}

if [[ $# -eq 0 ]]; then
  usage
fi

vx_ui_id=$( id -u vx-ui )

sudo -u vx-ui XDG_RUNTIME_DIR=/run/user/${vx_ui_id} pactl $@
