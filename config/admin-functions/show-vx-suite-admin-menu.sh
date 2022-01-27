#!/usr/bin/env bash

set -euo pipefail

: "${VX_FUNCTIONS_ROOT:="$(dirname "$0")"}"
: "${VX_CONFIG_ROOT:="/vx/config"}"

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
  echo -e "Machine Manufacturer: \e[32m${VX_MACHINE_MANUFACTURER}\e[0m"
  echo -e "Machine Model Name: \e[32m${VX_MACHINE_MODEL_NAME}\e[0m"

  if [[ $(lsblk | grep "vroot") ]]; then
	  echo -e "Lockdown state: \e[32mLocked Down\e[0m"
  else
	  echo -e "Lockdown state: \e[31mNot locked down\e[0m"
  fi

  timedatectl status | grep "Local time" | sed 's/^ *//g'

  if [ "${VX_MACHINE_TYPE}" = bmd ]; then
    echo -e "App Mode: \e[32m${VX_APP_MODE}\e[0m"
  fi

  CHOICES=('reboot')

  echo
  echo "${#CHOICES[@]}. Set Machine ID"
  CHOICES+=('set-machine-id')

  echo "${#CHOICES[@]}. Set Machine Model Name"
  CHOICES+=('set-machine-model-name')

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

  echo "${#CHOICES[@]}. Generate new signing keys"
  CHOICES+=('keygen')

  echo "${#CHOICES[@]}. Show current public signing key"
  CHOICES+=('keyshow')

  echo "${#CHOICES[@]}. Lock the system down."
  CHOICES+=('lockdown')

  echo "${#CHOICES[@]}. Reset System Authentication Code"
  CHOICES+=('resettotp')

  
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

    set-machine-model-name)
      "${VX_FUNCTIONS_ROOT}/choose-vx-machine-model-name.sh"
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

    keygen)
        rm -f "${VX_CONFIG_ROOT}/key.pub" "${VX_CONFIG_ROOT}/key.sec"
        signify-openbsd -G -n -p "${VX_CONFIG_ROOT}/key.pub" -s "${VX_CONFIG_ROOT}/key.sec"
        # Make the signing key readable by vx-group
        # We may want to further limit this in the future
        chgrp vx-group "${VX_CONFIG_ROOT}/key.sec"
        chmod g+r "${VX_CONFIG_ROOT}/key.sec"
        cat "${VX_CONFIG_ROOT}/key.pub" | qrencode -t ASCII -o -
        read -s -n 1
    ;;

    keyshow)
        cat "${VX_CONFIG_ROOT}/key.pub" | qrencode -t ASCII -o -
        read -s -n 1
    ;;
    
    resettotp)
        sudo tpm2-totp clean || true
        sudo tpm2-totp --pcrs=0,7 init
        read -s -n 1
    ;;
    
    lockdown)
        sudo "${VX_FUNCTIONS_ROOT}/lockdown.sh"
        read -s -n 1
    ;;
    

    *)
      echo -e "\e[31mUnknown menu item: ${CHOICE_INDEX}\e[0m" >&2
      read -s -n 1
    ;;

  esac
done
