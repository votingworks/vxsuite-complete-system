#!/usr/bin/env bash
#
# This script enables strict management of the systemd-networkd service
# It only supports specific command line arguments rather than granting
# less restrictive actions

set -euo pipefail

service_action=$1

if [[ -z ${service_action} ]]; then
  echo "Usage: $0 action"
  echo "Valid actions: enable, disable"
  exit 1
fi

if [[ ${service_action} == "enable" ]]; then
  systemctl enable --now systemd-networkd.socket
  systemctl enable --now systemd-networkd
elif [[ ${service_action} == "disable" ]]; then
  systemctl disable --now systemd-networkd.socket
  systemctl disable --now systemd-networkd
else
  echo "Error: ${service_action} is not a valid option"
  echo "Valid actions: enable, disable"
  exit 1
fi

exit 0
