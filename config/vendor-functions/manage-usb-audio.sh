#!/usr/bin/env bash
#
# This script controls the availability of the audio output on the USB tactile
# controller for VxMark.

trap '' SIGINT SIGTSTP SIGQUIT

set -euo pipefail

disable_rule_file="/etc/udev/rules.d/48-tactile-controller-audio.rules"
disable_rule='SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="0d8c", ATTRS{idProduct}=="0170", ATTR{bInterfaceClass}=="01", ATTR{authorized}="0"'

default_state="disable"
state_file="/vx/config/usb-audio-state"
cmd_line_override=${1:-disable}
service_action="disable"

if [[ $# -eq 1 ]]; then
  if [[ ${cmd_line_override} == "enable" ]]; then
    service_action="enable"
  elif [[ ${cmd_line_override} == "disable" ]]; then
    service_action="disable"
  else
    echo "Error: ${cmd_line_override} is not a valid option"
    echo "Valid actions: enable, disable"
    exit 1
  fi
else
  if [[ -f ${state_file} ]]; then
    state_file_content=$(head -c 8 -- "${state_file}")
    case "${state_file_content}" in
      enable|disable) service_action="${state_file_content}" ;;
      *) service_action="${default_state}" ;;
    esac
  else
    service_action="${default_state}"
  fi
fi

if [[ ${service_action} == "enable" ]]; then
  rm -f "${disable_rule_file}"
  echo "enable" > "${state_file}"
elif [[ ${service_action} == "disable" ]]; then
  echo "${disable_rule}" > "${disable_rule_file}"
  echo "disable" > "${state_file}"
else
  echo "Error: ${service_action} is not a valid option"
  echo "Valid actions: enable, disable"
  exit 1
fi

exit 0
