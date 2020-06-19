#!/usr/bin/env bash

set -euo pipefail

: "${VX_ROOT:="/vx-admin"}"
: "${VX_FUNCTIONS_ROOT:="${VX_ROOT}/admin-functions"}"
: "${VX_CONFIG_ROOT:="${HOME}/.config"}"

prompt-to-restart() {
  read -s -e -n 1 -p "Success! You must reboot for this change to take effect. Reboot now? [Yn] "
  if [[ ${REPLY} = "" || ${REPLY} = Y || ${REPLY} = y ]]; then
    sudo reboot
  fi
}

while true; do
  source "${VX_FUNCTIONS_ROOT}/read-vx-machine-config.sh"
  clear

  echo -e "\e[1mVxSuite Admin\e[0m"
  echo -e "Machine ID: \e[32m${VX_MACHINE_ID}\e[0m"
  echo -e "Machine Type: \e[32m${VX_MACHINE_TYPE}\e[0m"

  if [ "${VX_MACHINE_TYPE}" = bmd ]; then
    echo -e "App Mode: \e[32m${VX_APP_MODE}\e[0m"
  fi

  CHOICES=('reboot')

  echo
  echo "${#CHOICES[@]}. Set Machine ID"
  CHOICES+=('set-machine-id')

  if [ "${VX_MACHINE_TYPE}" = bmd ]; then
    echo "${#CHOICES[@]}. Set app mode"
    CHOICES+=('set-app-mode')
  fi

  echo "${#CHOICES[@]}. View system logs"
  CHOICES+=('view-system-logs')

  echo "0. Reboot"
  echo
  read -p "Select menu item: " CHOICE_INDEX

  CHOICE=${CHOICES[$CHOICE_INDEX]}
  case "${CHOICE}" in
    reboot)
      sudo reboot
    ;;

    set-machine-id)
      "${VX_FUNCTIONS_ROOT}/choose-vx-machine-id.sh"
      prompt-to-restart
    ;;

    set-app-mode)
      if [ "${VX_MACHINE_TYPE}" = bmd ]; then
        "${VX_FUNCTIONS_ROOT}/choose-vx-mark-app-mode.sh"
        prompt-to-restart
      fi
    ;;

    view-system-logs)
      less +F /var/log/syslog
    ;;

    *)
      echo -e "\e[31mUnknown menu item: ${CHOICE_INDEX}\e[0m" >&2
      read -s -n 1
    ;;
  esac
done
