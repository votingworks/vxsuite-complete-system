#!/bin/bash

set -euo pipefail

# TODO?: support passing multiple partitions

rekey_flag='/home/REKEY_VIA_TPM'

# check for flag file created by lockdown.sh only run if exists
if [ ! -f ${rekey_flag} ]; then
  echo "NOTE: No flag file exists to encrypt via the TPM. Skipping this step."
  sleep 5
  exit 0
fi

# check for tpm2 only run if exists
if [ ! -f /sys/class/tpm/tpm0/tpm_version_major ]; then
  echo "No TPM chip was detected. Skipping TPM disk encryption."
  sleep 5
  exit 0
else
  if ! grep '^2' /sys/class/tpm/tpm0/tpm_version_major > /dev/null; then
    echo "TPM is not version 2. Skipping TPM disk encryption."
    sleep 5
    exit 0
  fi
fi

# check for crypttab entry only run if present and configured for tpm
if ! grep '^var_decrypted' /etc/crypttab > /dev/null; then
  echo "There is no crypttab entry. Skipping TPM disk encryption."
  sleep 5
  exit 0
else
  if ! grep 'luks,tpm2-device=auto' /etc/crypttab > /dev/null; then
    echo "The crypttab entry is not configured to use TPM. Skipping TPM disk encryption."
    sleep 5
    exit 0
  fi
fi

# check for tpm2-tools installed only run if found; otherwise, you can break boot
# NOTE: If we get here, the machine will only be bootable by manually entering
#       the insecure passphrase on every boot
if ! tpm2_selftest -v > /dev/null 2>&1; then
  echo "The necessary tpm2 tools are not installed. Skipping TPM disk encryption."
  sleep 5
  exit 0
fi

# check that Secure Boot is enabled
secure_boot_state=$(mokutil --sb-state | grep SecureBoot | cut -d' ' -f2)
if [[ $secure_boot_state != "enabled" ]]; then
  echo "Secure Boot is not enabled. Please enable it via the BIOS."
  echo "(VxMark may only require a reboot since the BIOS is limited.)"
  echo "Rebooting to BIOS in 10 seconds..."
  sleep 10
  systemctl reboot --firmware
fi

# check for VotingWorks signed PK
# Note: The ${var,,} syntax lowercases the variable content
secure_boot_signer=$(mokutil --pk | grep Issuer | cut -d'=' -f2)
if [[ ${secure_boot_signer,,} =~ "votingworks" ]]; then
  echo "VotingWorks secure boot keys are not installed."
  echo "Please configure the BIOS to Secure Boot Setup Mode and install the required keys."
  echo "Rebooting to BIOS in 10 seconds..."
  sleep 10
  systemctl reboot --firmware
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

rm -f ${rekey_flag}

echo "${partition_path} encryption key has been stored in the TPM."

exit 0;
