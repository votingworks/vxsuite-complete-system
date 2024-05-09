#!/usr/bin/env bash

setfont /usr/share/consolefonts/Lat7-Terminus32x16.psf.gz 

set -euo pipefail

: "${VX_FUNCTIONS_ROOT:="$(dirname "$0")"}"
: "${VX_CONFIG_ROOT:="/vx/config"}"
: "${VX_METADATA_ROOT:="/vx/code"}"

if [[ $(tty) = /dev/tty1 ]] && [[ -f "/home/REKEY_VIA_TPM" ]]; then
  sudo "${VX_FUNCTIONS_ROOT}/rekey-via-tpm.sh"
fi

if [[ $(tty) = /dev/tty1 ]] && [[ -f "${VX_CONFIG_ROOT}/RUN_BASIC_CONFIGURATION_ON_NEXT_BOOT" ]]; then
  "${VX_FUNCTIONS_ROOT}/basic-configuration.sh"
  exit 0
fi

prompt-to-restart() {
  read -s -e -n 1 -p "Success! You must reboot for this change to take effect. Reboot now? (y/n) "
  if [[ ${REPLY} = "" || ${REPLY} = Y || ${REPLY} = y ]]; then
    sudo /usr/sbin/reboot
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
  if [ "${VX_MACHINE_TYPE}" = "mark" ]; then
    echo -e "Machine App Mode: \e[32m${VX_APP_MODE}\e[0m"
  fi

  # TODO: do we want to try to also display secure boot status? 
  if [[ $(lsblk | grep "vroot") ]]; then
    echo -e "Lockdown State: \e[32mLocked Down\e[0m"
  else
    echo -e "Lockdown State: \e[31mNot Locked Down\e[0m"
  fi

  if [[ $(mokutil --sb-state | grep "enabled") ]]; then
    echo -e "Secure Boot State: \e[32mEnabled\e[0m"
  else
    echo -e "Secure Boot State: \e[31mDisabled\e[0m"
    fi
  echo -e

  echo "Current Time: $(date)"


  CHOICES=('reboot')

  echo
  echo -e "\e[1mBasic Configuration\e[0m"
  echo "${#CHOICES[@]}. Run Basic Configuration Wizard"
  CHOICES+=('basic-configuration')

  echo "${#CHOICES[@]}. Run Basic Configuration Wizard On Next Boot"
  CHOICES+=('basic-configuration-on-next-boot')

  echo
  echo -e "\e[1mAdvanced\e[0m"
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

  echo "${#CHOICES[@]}. Recreate Machine Cert"
  CHOICES+=('recreate-machine-cert')

  echo "${#CHOICES[@]}. Reset System Authentication Code"
  CHOICES+=('reset-totp')

  echo "${#CHOICES[@]}. Setup Boot Entry"
  CHOICES+=('setup-boot-entry')

  echo "${#CHOICES[@]}. Lock the System Down"
  CHOICES+=('lockdown')

  echo "${#CHOICES[@]}. Show Image Hash Signature"
  CHOICES+=('hash-signature')

  # Keep conditional choices at the end so that the numbering of the other choices is consistent
  # across machines

  if [ "${VX_MACHINE_TYPE}" = "admin" ]; then
    echo "${#CHOICES[@]}. Program System Administrator Cards"
    CHOICES+=('program-system-administrator-cards')
  fi

  if [ "${VX_MACHINE_TYPE}" = "mark" ]; then
    echo "${#CHOICES[@]}. Set App Mode"
    CHOICES+=('set-app-mode')
  fi

  echo "0. Reboot"
  echo
  read -p "Select menu item: " CHOICE_INDEX

  CHOICE=${CHOICES[$CHOICE_INDEX]}
  case "${CHOICE}" in
    reboot)
      sudo /usr/sbin/reboot
    ;;

    basic-configuration)
      "${VX_FUNCTIONS_ROOT}/basic-configuration.sh"
    ;;

    basic-configuration-on-next-boot)
      touch "${VX_CONFIG_ROOT}/RUN_BASIC_CONFIGURATION_ON_NEXT_BOOT"
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
      if [ "${VX_MACHINE_TYPE}" = "mark" ]; then
        "${VX_FUNCTIONS_ROOT}/choose-vx-mark-app-mode.sh"
        prompt-to-restart
      fi
    ;;

    copy-system-logs)
      "${VX_FUNCTIONS_ROOT}/copy-logs.sh"      
    ;;

    set-clock)
      sudo "${VX_FUNCTIONS_ROOT}/set-clock.sh"
    ;;

    change-password)
      passwd
    ;;

    generate-key)
      sudo "${VX_FUNCTIONS_ROOT}/generate-key.sh"
      read -s -n 1
      echo
      echo "Generating a new machine private key necessitates recreating the machine cert"
      sudo "${VX_FUNCTIONS_ROOT}/create-machine-cert.sh"

      if [[ "${VX_MACHINE_TYPE}" = "admin" ]]; then
        echo
        echo "Recreating the machine cert might necessitate reprogramming system administrator cards"
        sudo "${VX_FUNCTIONS_ROOT}/program-system-administrator-cards.sh"
      fi
    ;;

    show-key)
      "${VX_FUNCTIONS_ROOT}/show-key.sh"
      read -s -n 1
    ;;

    recreate-machine-cert)
      sudo "${VX_FUNCTIONS_ROOT}/create-machine-cert.sh"

      if [[ "${VX_MACHINE_TYPE}" = "admin" ]]; then
        echo
        echo "Recreating the machine cert might necessitate reprogramming system administrator cards"
        sudo "${VX_FUNCTIONS_ROOT}/program-system-administrator-cards.sh"
      fi
    ;;

    program-system-administrator-cards)
      sudo "${VX_FUNCTIONS_ROOT}/program-system-administrator-cards.sh"
    ;;
    
    reset-totp)
      "${VX_FUNCTIONS_ROOT}/reset-totp.sh"
      read -s -n 1
    ;;
    
    lockdown)
      sudo "${VX_FUNCTIONS_ROOT}/lockdown.sh"
      read -s -n 1
    ;;

    hash-signature)
      sudo "${VX_FUNCTIONS_ROOT}/hash-signature.sh"
    ;;
    
    setup-boot-entry)
      sudo "${VX_FUNCTIONS_ROOT}/setup-boot-entry.sh"
      read -s -n 1
    ;;

    *)
      echo -e "\e[31mUnknown menu item: ${CHOICE_INDEX}\e[0m" >&2
      read -s -n 1
    ;;

  esac
done
