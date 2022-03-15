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
  if [ "${VX_MACHINE_TYPE}" = bmd ]; then
    echo -e "Machine App Mode: \e[32m${VX_APP_MODE}\e[0m"
  fi

  # TODO: do we want to try to also display secure boot status? 
  if [[ $(lsblk | grep "vroot") ]]; then
    echo -e "Lockdown State: \e[32mLocked Down\e[0m"
  else
    echo -e "Lockdown State: \e[31mNot Locked Down\e[0m"
  fi

  echo "Current Time: $(date)"


  CHOICES=('reboot')

  echo
  echo "${#CHOICES[@]}. Set Machine ID"
  CHOICES+=('set-machine-id')

  echo "${#CHOICES[@]}. Set Machine Model Name"
  CHOICES+=('set-machine-model-name')

  echo "${#CHOICES[@]}. Copy System Logs to USB"
  CHOICES+=('copy-system-logs')

  echo "${#CHOICES[@]}. Set Clock"
  CHOICES+=('set-clock')
  
  echo "${#CHOICES[@]}. Change Password"
  CHOICES+=('change-password')

  echo "${#CHOICES[@]}. Generate New Signing Keys"
  CHOICES+=('generate-key')

  echo "${#CHOICES[@]}. Show Current Public Signing Key"
  CHOICES+=('show-key')

  echo "${#CHOICES[@]}. Reset System Authentication Code"
  CHOICES+=('reset-totp')

  echo "${#CHOICES[@]}. Setup Boot Entry"
  CHOICES+=('setup-boot-entry')

  echo "${#CHOICES[@]}. Lock the System Down"
  CHOICES+=('lockdown')

  # Keep this one at the end so that doesn't change the numbering of other choices
  if [ "${VX_MACHINE_TYPE}" = bmd ]; then
    echo "${#CHOICES[@]}. Set App Mode"
    CHOICES+=('set-app-mode')
  fi

  
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

    generate-key)
      "${VX_FUNCTIONS_ROOT}/generate-key.sh"
      read -s -n 1
    ;;

    show-key)
      "${VX_FUNCTIONS_ROOT}/show-key.sh"
      read -s -n 1
    ;;
    
    reset-totp)
      "${VX_FUNCTIONS_ROOT}/reset-totp.sh"
      read -s -n 1
    ;;
    
    lockdown)
      sudo "${VX_FUNCTIONS_ROOT}/lockdown.sh"
      read -s -n 1
    ;;
    
    setup-boot-entry)
      "${VX_FUNCTIONS_ROOT}/setup-boot-entry.sh"
      read -s -n 1
    ;;

    *)
      echo -e "\e[31mUnknown menu item: ${CHOICE_INDEX}\e[0m" >&2
      read -s -n 1
    ;;

  esac
done
