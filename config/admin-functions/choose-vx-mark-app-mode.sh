#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"

while true; do
  echo 'VxMark App Mode:'
  echo '1. VxMark'
  echo '2. VxPrint'
  echo '3. VxMark + VxPrint'
  read -p 'Choose one: ' APP_MODE

  case "${APP_MODE}" in
    1)
      echo 'VxMark' > "${VX_CONFIG_ROOT}/app-mode"
      break
    ;;

    2)
      echo 'VxPrint' > "${VX_CONFIG_ROOT}/app-mode"
      break
    ;;

    3)
      echo 'VxMark + VxPrint' > "${VX_CONFIG_ROOT}/app-mode"
      break
    ;;

    '')
      echo 'Please choose an app mode!' >&2
    ;;

    *)
      echo "Invalid app mode: ${APP_MODE}" >&2
    ;;
  esac
done
