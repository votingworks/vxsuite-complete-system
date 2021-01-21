#!/usr/bin/env bash

set -euo pipefail

: "${VX_FUNCTIONS_ROOT:="$(dirname "$0")"}"

prompt-to-restart() {
  read -s -e -n 1 -p "Success! You must reboot for this change to take effect. Reboot now? [Yn] "
  if [[ ${REPLY} = "" || ${REPLY} = Y || ${REPLY} = y ]]; then
    sudo reboot
  fi
}

while true; do
  source "${VX_FUNCTIONS_ROOT}/../read-vx-machine-config.sh"
  clear

  echo -e "\e[1mVxSuite Admin\e[0m"
  echo -e "Code Version: \e[32m${VX_CODE_VERSION}\e[0m"
  echo -e "Machine ID: \e[32m${VX_MACHINE_ID}\e[0m"
  echo -e "Machine Type: \e[32m${VX_MACHINE_TYPE}\e[0m"
  timedatectl status | grep "Local time" | sed 's/^ *//g'

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

  echo "${#CHOICES[@]}. Copy system logs to USB"
  CHOICES+=('copy-system-logs')

  echo "${#CHOICES[@]}. Set Clock"
  CHOICES+=('set-clock')
  
  echo "${#CHOICES[@]}. Change Password"
  CHOICES+=('change-password')
  
  echo "0. Reboot"
  echo
  read -p "Select menu item: " CHOICE_INDEX

  CHOICE=${CHOICES[$CHOICE_INDEX]}
  case "${CHOICE}" in
    reboot)
	# this doesn't need root
	systemctl reboot -i
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

    copy-system-logs)
      "${VX_FUNCTIONS_ROOT}/copy-logs.sh"      
    ;;

    set-clock)
      "${VX_FUNCTIONS_ROOT}/set-clock.sh"
    ;;

    change-password)
      passwd
    ;;
    
    *)
      echo -e "\e[31mUnknown menu item: ${CHOICE_INDEX}\e[0m" >&2
      read -s -n 1
    ;;
  esac
done
