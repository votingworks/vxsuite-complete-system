#!/usr/bin/env bash

set -euo pipefail

: "${VX_CONFIG_ROOT:="/vx/config"}"

while true; do
  echo 'VxMark App Mode:'
  echo '1. MarkOnly'
  echo '2. PrintOnly'
  echo '3. MarkAndPrint'
  read -p 'Choose one: ' APP_MODE

  case "${APP_MODE}" in
    1)
      echo 'MarkOnly' > "${VX_CONFIG_ROOT}/app-mode"
      break
    ;;

    2)
      echo 'PrintOnly' > "${VX_CONFIG_ROOT}/app-mode"
      break
    ;;

    3)
      echo 'MarkAndPrint' > "${VX_CONFIG_ROOT}/app-mode"
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
