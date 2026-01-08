#!/bin/bash

set -euo pipefail

# Since this script excecutes well before the entirety of systemd
# is available, we have to effectively recreate what:
# systemctl reboot --firmware-setup
# accomplishes. We do that by setting the necessary reboot_to_firmware
# flag in the OsIndications file, followed by a forced, immediate reboot
# to the BIOS
# We can't use regular reboot commands because systemd services will
# continue to execute, setting "completed" flag files that we don't
# want set if this script fails
function firmware_reboot () {
  os_indications_path='/sys/firmware/efi/efivars/OsIndications-8be*'
  os_indications_path=$(ls -1 "$os_indications_path" | tail -1)
  reboot_to_firmware='\x07\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00'
  #                   └───────┬──────┘└───────────────┬──────────────┘
  #                     4 bytes attrs (0x00000007)     8 bytes value (0x0000000000000001)
  #                     = NV + BootSvc + Runtime       = BOOT_TO_FW_UI bit set

  echo "Path: $os_indications_path"

  if [ -w "$os_indications_path" ]; then
    printf "$reboot_to_firmware" > "$os_indications_path"
  else
    echo "ERROR: OsIndications not found"
  fi

  # force immediate reboot
  echo b > /proc/sysrq-trigger

  # execution should never get here, but included for completeness
  exit 1
}

# TODO?: support passing multiple partitions

# check for tpm2 only run if exists
# Should the exit status be 0?
if [ ! -f /sys/class/tpm/tpm0/tpm_version_major ]; then
  echo "No TPM chip was detected. Skipping TPM disk encryption."
  sleep 5
  exit 1
else
  if ! grep '^2' /sys/class/tpm/tpm0/tpm_version_major > /dev/null; then
    echo "TPM is not version 2. Skipping TPM disk encryption."
    sleep 5
    exit 1
  fi
fi

# check for crypttab entry only run if present and configured for tpm
# Should the exit status be 0?
if ! grep '^var_decrypted' /etc/crypttab > /dev/null; then
  echo "There is no crypttab entry. Skipping TPM disk encryption."
  sleep 5
  exit 1
else
  if ! grep 'luks,tpm2-device=auto' /etc/crypttab > /dev/null; then
    echo "The crypttab entry is not configured to use TPM. Skipping TPM disk encryption."
    sleep 5
    exit 1
  fi
fi

# check for tpm2-tools installed only run if found; otherwise, you can break boot
# Should the exit status be 0?
# NOTE: If we get here, the machine will only be bootable by manually entering
#       the insecure passphrase on every boot
if ! tpm2_selftest -v > /dev/null 2>&1; then
  echo "The necessary tpm2 tools are not installed. Skipping TPM disk encryption."
  sleep 5
  exit 1
fi

# check that Secure Boot is enabled
secure_boot_state=$(mokutil --sb-state | grep SecureBoot | cut -d' ' -f2)
if [[ $secure_boot_state != "enabled" ]]; then
  echo "Secure Boot is not enabled. Please enable it via the BIOS."
  echo "(VxMarkScan may only require a reboot since the BIOS is limited.)"
  echo "Rebooting to BIOS in 10 seconds..."
  sleep 10
  firmware_reboot
fi

# check for VotingWorks signed PK
# Note: The ${var,,} syntax lowercases the variable content
secure_boot_signer=$(mokutil --pk | grep Issuer | cut -d'=' -f2)
if [[ ! ${secure_boot_signer,,} =~ "votingworks" ]]; then
  echo "VotingWorks secure boot keys are not installed."
  echo "Please configure the BIOS to Secure Boot Setup Mode and install the required keys."
  echo "Rebooting to BIOS in 10 seconds..."
  sleep 10
  firmware_reboot
fi

# TODO: add a check via luksDump to see if TPM is already in use

encrypted_dev_path='/dev/Vx-vg/var_encrypted'
insecure_key='/home/insecure.key'
random_key='/home/random.key'
partition_path='/var'

echo "Creating a random keyfile..."
dd if=/dev/urandom of=${random_key} bs=512 count=4
chmod 0400 ${random_key}

echo "Enrolling random keyfile to luks..."
cryptsetup luksAddKey --key-file ${insecure_key} ${encrypted_dev_path} ${random_key}

echo "Removing original passphrase..."
cryptsetup luksRemoveKey --key-file ${insecure_key} ${encrypted_dev_path}

echo "Re-encrypting ${partition_path} with random key. This will take several minutes..."
cryptsetup reencrypt ${encrypted_dev_path} --key-file ${random_key}

echo "Enrolling random key into the TPM..."
systemd-cryptenroll --unlock-key-file=${random_key} --tpm2-device=auto ${encrypted_dev_path}

echo "Removing the random keyfile from luks..."
cryptsetup luksRemoveKey --key-file ${random_key} ${encrypted_dev_path}

echo "Removing all keyfiles from disk..."
shred -uvz ${insecure_key}
shred -uvz ${random_key}

echo "${partition_path} encryption key has been stored in the TPM."

exit 0;
