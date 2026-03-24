#!/usr/bin/env bash
#
# This script enables strict management of the systemd-networkd service
# It only supports specific command line arguments rather than granting
# less restrictive actions

set -euo pipefail

state_file="/vx/config/local-ethernet-state"
default_state="disable"
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
  systemctl enable --runtime --now systemd-networkd.socket systemd-networkd
  echo "enable" > "${state_file}"
elif [[ ${service_action} == "disable" ]]; then
  systemctl disable --runtime --now systemd-networkd.socket systemd-networkd
  echo "disable" > "${state_file}"
else
    echo "Error: ${service_action} is not a valid option"
    echo "Valid actions: enable, disable"
    exit 1
fi

exit 0
