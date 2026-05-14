#!/bin/bash

set -euo pipefail

usage () {
  echo "Usage: pactl <options>"
  exit 1
}

if [[ $# -eq 0 ]]; then
  usage
fi

if id vx-ui > /dev/null 2>&1; then
  user=vx-ui
elif id vx > /dev/null 2>&1; then
  user=vx
else
  user=$( whoami )
fi

userid=$( id -u ${user} )

sudo -u $user XDG_RUNTIME_DIR=/run/user/${userid} pactl "$@"
