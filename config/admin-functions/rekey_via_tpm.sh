#!/bin/bash

# TODO: add error checking
# TODO?: support passing multiple partitions
encrypted_dev_path='/dev/Vx-vg/var_encrypted'
insecure_key='/home/insecure.key'
random_key='/home/random.key'
partition_path='/var'

# check for flag file created by lockdown.sh only run if exists
# check for tpm2 only run if exists
# check for crypttab entry only run if configured for tpm
# check for tpm2-tools installed only run if found

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
