set -euo pipefail 

# Now do the dm-verity setup
sudo veritysetup format --debug /dev/mapper/VxMark--vg-root /dev/mapper/VxMark--vg-hashes| tee "/tmp/verity.log"

# Find the root hash and append it to our cmdline
HASH="$(awk '/Root hash:/ { print $3 }' "/tmp/verity.log")"
echo "$(cat config/cmdline)${HASH}" > cmdline

# Now package up ouer kernel, cmdline, etc
sudo objcopy \
    --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \
    --add-section .cmdline="cmdline" --change-section-vma .cmdline=0x30000 \
    --add-section .splash="config/logo.bmp" --change-section-vma .splash=0x40000 \
    --add-section .linux="/boot/vmlinuz-5.10.0-10-amd64" --change-section-vma .linux=0x2000000 \
    --add-section .initrd="/boot/initrd.img-5.10.0-10-amd64" --change-section-vma .initrd=0x3000000 \
    "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" "linux.efi"

# Sign the resulting binary
sudo sbsign --key=KEK.key --cert KEK.crt --output /boot/efi/EFI/debian/VxLinux-signed.efi linux.efi

# Now install it 
DEV="$(df "$OUTDIR" | tail -1 | cut -d' ' -f1)"
part=$(cat /sys/class/block/$(basename $DEV)/partition)

sudo efibootmgr \
	--quiet \
	--create \
	--disk "$DEV" \
	--part $part \
	--label "VxLinux" \
	--loader "\\EFI\\debian\\VxLinux-signed.efi" \

