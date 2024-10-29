#!/usr/bin/env bash

# Requires sudo

set -euo pipefail

: "${VX_METADATA_ROOT:="/vx/code"}"

function get_usb_drives_json() {
    (lsblk /dev/disk/by-id/usb*part* -o LABEL,NAME,SIZE,PATH --json 2> /dev/null || true) | jq ".blockdevices"
}

while true; do
    usb_drives_json="$(get_usb_drives_json)"
    if [[ "${usb_drives_json}" == "[]" ]]; then
        read -p "No USB drives found. Press enter to try again. "
    else
        # Pretty print the detected USB drives, prefixed with numeric indexes
        readarray -t usb_drives <<< "$(jq -r ".[] | [.label, .name, .path, .size] | @tsv" <<< "${usb_drives_json}")"
        echo
        echo "USB drive(s) detected:"
        for i in "${!usb_drives[@]}"; do
            echo "${i}. ${usb_drives[i]}"
        done
        echo

        while true; do
            read -p "Enter the index (0, 1, etc.) of the USB drive that you'd like to use, or press enter to search for USB drives again: " index
            if [[ -z "${index}" ]]; then
                # Search for USB drives again
                break 1
            elif ! [[ "${index}" =~ ^[0-9]+$ ]]; then
                echo -e "\e[31mInvalid index\e[0m" >&2
            else
                selected_usb_drive_device_path="$(jq -r ".[${index}].path" <<< "${usb_drives_json}")"
                if [[ "${selected_usb_drive_device_path}" == "null" ]]; then
                    echo -e "\e[31mInvalid index\e[0m" >&2
                else
                    # USB drive selected
                    break 2
                fi
            fi
        done
    fi
done

# Unmount USB drive if already mounted then mount selected USB drive
"${VX_METADATA_ROOT}/app-scripts/unmount-usb.sh" 2> /dev/null || true
"${VX_METADATA_ROOT}/app-scripts/mount-usb.sh" "${selected_usb_drive_device_path}"
