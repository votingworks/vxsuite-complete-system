#!/bin/bash
set -euo pipefail 

: "${VX_FUNCTIONS_ROOT:="$(dirname "$0")"}"
: "${VX_CONFIG_ROOT:="/vx/config"}"

echo "Are you sure you want to proceed with lockdown? [Y/n]:" 

read -r answer

if [[ $answer == 'n' || $answer == 'N' ]]; then
    echo "Not locking down. Exiting..."
    sleep 3
    exit
fi

# Since we shutdown after this script now, let's add a check related
# to basic configuration on first boot
if [[ ! -f "${VX_CONFIG_ROOT}/RUN_BASIC_CONFIGURATION_ON_NEXT_BOOT" ]]; then
  echo "This system is not configured to run the basic configuration wizard on first boot. Would you like to configure that now? [y/n]: "
  read -r enable_config
  if [[ $enable_config == 'n' || $enable_config == 'N' ]]; then
    echo "Skipping basic configuration wizard on next boot."
  else
    echo "Enabling basic configuration wizard on next boot."
    touch "${VX_CONFIG_ROOT}/RUN_BASIC_CONFIGURATION_ON_NEXT_BOOT"
  fi
fi

# Since this script is pretty destructive if something goes wrong
# check that the signing keys are mounted before proceeding, exit if not
umount /dev/sda || true
umount /dev/sda1 || true
mount /dev/sda /mnt || mount /dev/sda1 /mnt || (echo "Secure boot keys not found; exiting" && sleep 5 && exit);
umount /mnt

# We don't need to sign i915 since it is signed by Debian's Secure Boot key
# and we have access to that under Secure Boot. 
# However, if we do ever need to use an unsigned module, the below code 
# will sign with the VotingWorks key.
# You would just add modules to the var, e.g. modules_to_sign="i915 mod2 mod3"
modules_to_sign=""
if [[ -n $modules_to_sign ]]; then
  read -s -p "Please enter the passphrase for the secure boot key: " KBUILD_SIGN_PIN

  export KBUILD_SIGN_PIN

  umount /dev/sda || true
  umount /dev/sda1 || true
  mount /dev/sda /mnt || mount /dev/sda1 /mnt || (echo "Secure boot keys not found; exiting" && sleep 5 && exit);

  for module in ${modules_to_sign}
  do
    if modinfo -n "${module}" 2>&1 > /dev/null; then
      /usr/src/linux-kbuild-6.1/scripts/sign-file sha256 /mnt/DB.key /mnt/DB.crt $(modinfo -n "${module}")
    fi
  done
fi

# Since we are locking down, we need to modify /etc/crypttab to use the TPM
# Also set the flag file to run the actual rekey-via-tpm.sh script on first boot
# Only do this if the crypttab is already configured, just in case
if grep '^var_decrypted' /etc/crypttab > /dev/null; then
  sed -i -e /^var_decrypted/d /etc/crypttab
  echo "var_decrypted /dev/Vx-vg/var_encrypted none try-empty-password,luks,tpm2-device=auto" >> /etc/crypttab
  touch /home/REKEY_VIA_TPM
fi

# enable the vx-cleanup service one more time to clear out
# any logs generated during the lockdown phase
systemctl daemon-reload
systemctl enable vx-cleanup.service

update-initramfs -u

# Remount / so it can't change while we're doing the veritysetup
cd /tmp
mount -o ro,remount /

# Now do the dm-verity setup
veritysetup format /dev/mapper/Vx--vg-root /dev/mapper/Vx--vg-hashes| tee "/tmp/verity.log"

# Find the root hash and append it to our cmdline
HASH="$(awk '/Root hash:/ { print $3 }' "/tmp/verity.log")"
echo "$(cat /vx/vendor/config/cmdline)${HASH}" > /tmp/cmdline

KERNEL_VERSION=$(uname -r)


# Now package up our kernel, cmdline, etc...
objcopy \
    --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \
    --add-section .cmdline="/tmp/cmdline" --change-section-vma .cmdline=0x30000 \
    --add-section .splash="/vx/vendor/config/logo.bmp" --change-section-vma .splash=0x40000 \
    --add-section .linux="/boot/vmlinuz-${KERNEL_VERSION}" --change-section-vma .linux=0x2000000 \
    --add-section .initrd="/boot/initrd.img-${KERNEL_VERSION}" --change-section-vma .initrd=0x3000000 \
    "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" "/tmp/linux.efi"

# Sign the resulting binary
# First make sure the drive is mounted
umount /dev/sda || true
umount /dev/sda1 || true
mount /dev/sda /mnt || mount /dev/sda1 /mnt || (echo "Secure boot keys not found; exiting" && sleep 5 && exit);

sbsign --key=/mnt/DB.key --cert=/mnt/DB.crt --output /boot/efi/EFI/debian/VxLinux-signed.efi /tmp/linux.efi

# Now install it 
bash "${VX_FUNCTIONS_ROOT}/setup-boot-entry.sh"

# Output the dm-verity hash
echo "SHA256 Hash: ${HASH}"
read -p "Press enter once you have recorded the system hash. "

# If we have the necessary tools, display the base64 version of the hash
if [[ $(which xxd) && $(which base64) ]]; then
  base64_hash=$( echo -n "${HASH}" | xxd -r -p | base64 )
  echo "Base64 Hash for SHV: ${base64_hash}"
  read -p "Press enter once you have recorded the base64 SHV hash. "
else
  echo "The tools required to convert the original system hash to base64 are not installed. You can still convert the original hash to the base64 version later."
  read -p "Press enter to continue. "
fi

# Shut down the locked down system
# We can't reboot this on the aws build machine due to encrypted /var
echo "Shutting down in 5s"
sleep 5
systemctl poweroff
