#!/bin/bash
set -eo pipefail

if [ "$EUID" -ne 0 ]; then
	echo "This script must run as root"
	exit 1
fi

#TMP="$(mktemp -d)"
mount -t tmpfs none "/tmp"
TMP=$(mktemp -d)


# Much of this was taken from Safeboot with minimal to no modification. 
# Set the default values for the other parameters
# Do not assign ROOTDEV or HASHDEV; they will be detected in rootdev-check
: "${DIR:=.}"
: "${ROOTDEV:=/dev/nvme0n1p3}"
: "${HASHDEV:=/dev/nvme0n1p2}"
: "${LINUX_TARGET:=linux}"
: "${RECOVERY_TARGET:=recovery}"
: "${SIP:=0}"
: "${PCRS:=0,2,5,7}"
: "${BOOTMODE_PCR:=14}"
: "${LINUX_COMMANDLINE:=ro quiet splash vt.handoff=7 intel_iommu=on efi=disable_early_pci_dma lockdown=confidentiality}"
: "${RECOVERY_COMMANDLINE:=${LINUX_COMMANDLINE}}"
: "${SEAL_PIN:=1}"
: "${PREFIX:=}"
: "${EFIDIR:=/boot/efi/EFI}"
: "${KERNEL:=/boot/vmlinuz}"
: "${INITRD:=/boot/initrd.img}"
: "${CERT:=cert.pem}"
: "${KEY:=cert.priv}"


#
# Ensure that there is a valid root device
#
rootdev-check()
{
	if [ -z "${ROOTDEV}" ]; then
		ROOTDEV="$(mount | awk '/ on \/ / { print $1 }')"
		echo "\$ROOTDEV is not set. Guessing $ROOTDEV"
		TEST_ROOTDEV=1
	fi

	if [ ! -e "$ROOTDEV" ]; then
		echo "$ROOTDEV: root device does not exist?"
		exit 1
	fi

	if [ ! -r "$ROOTDEV" ]; then
		echo "$ROOTDEV: root device permission denied"
		exit 1
	fi

	if [ "$TEST_ROOTDEV" = 1 ]; then
		echo "$PREFIX$DIR/local.conf: setting \$ROOTDEV=$ROOTDEV"
		echo "ROOTDEV=\"$ROOTDEV\"" >> $PREFIX$DIR/local.conf 
		TEST_ROOTDEV=0
	fi

	if [ -z "$HASHDEV" ]; then
		HASHDEV="${ROOTDEV%-*}-hashes"
		echo "\$HASHDEV is not set. Guessing $HASHDEV (same volume group as \$ROOTDEV)"
		TEST_HASHDEV=1
	fi

	if [ ! -e "$HASHDEV" ]; then
		echo "$HASHDEV: hash device does not exist. Please set in $PREFIX$DIR/local.conf"
		exit 1
	fi

	if [ ! -r "$HASHDEV" ]; then
		echo "$HASHDEV: hash device permission denied. Please set in $PREFIX$DIR/local.conf"
		exit 1
	fi

	if [ "$TEST_HASHDEV" = 1 ]; then
		echo "$PREFIX$DIR/local.conf: setting \$HASHDEV=$HASHDEV"
		echo "HASHDEV=\"$HASHDEV\"" >> $PREFIX$DIR/local.conf 
		TEST_HASHDEV=0
	fi
}


########################################

linux_sign_usage='
## linux-sign
Usage:
```
safeboot linux-sign [target-name [parameters...]]
```
Generate dm-verity hashes and then sign the Linux with the root hash added
to the kernel command line.  The default target for the EFI boot manager is
`linux`.  You will need the Yubikey or x509 password to sign the new hashes
and kernel.
If the environment variable `$HASH` is set to the hash value, or if
the `$HASHFILE` variable points to the previous dmverity log (typically
`/boot/efi/EFI/linux/verity.log`), then the precomputed value will be used
instead of recomputing the dmverity hashes (which can take some time).
If the hashes are out-of-date, this might render the `linux` target
unbootable and require a recovery reboot to re-hash the root filesystem.
'

usage+=$linux_sign_usage
commands+="|linux-sign"

linux-sign()
{
	rootdev-check -

	# default is linux
	if [ -n "$1" ]; then
		TARGET=$1
		shift
	else
		TARGET=${LINUX_TARGET}
	fi

	if mount | grep "^${ROOTDEV} " ; then \
		remount_ro "$ROOTDEV" 
	fi

	if [ -n "$HASH" ]; then
		echo "$ROOTDEV: Using hash $HASH"
	elif [ -n "$HASHFILE" ]; then
		echo "$ROOTDEV: Using hash file $HASFILE"
		HASH="$(awk '/Root hash:/ { print $3 }' "$HASHFILE")"
	else
		echo "$ROOTDEV: Computing hashes: this will take a while..."
		veritysetup format \
			--debug \
			"${ROOTDEV}" \
			"${HASHDEV}" \
			| tee "$TMP/verity.log" \

		HASH="$(awk '/Root hash:/ { print $3 }' "$TMP/verity.log")"
	fi

	if [ -z "$HASH" ]; then
		echo "$ROOTDEV: root hash not in log?"
		exit 1
	fi

	ROOT_ARGS="\
		root=/dev/nvme0n1p3 \
		fsck.mode=skip \
		verity.hashdev=${HASHDEV} \
		verity.rootdev=${ROOTDEV} \
		verity.hash=$HASH \
	"

	install-kernel "$TARGET" \
		"$LINUX_COMMANDLINE" \
		"$ROOT_ARGS" \
		"safeboot.mode=$TARGET" \
		"$@" \

	if [ -r "$TMP/verity.log" ]; then
		# stash a copy of the verity log in the boot directory
		# so that repeat signing can be done more quickly
		cp "$TMP/verity.log" "$OUTDIR"
	fi
}

########################################

install_kernel_usage='
## install-kernel
Usage:
```
safeboot install-kernel boot-name [extra kernel parameters...]
```
Create an EFI boot menu entry for `boot-name`, with the specified
kernel, initrd and command line bundled into an executable and signed.
This command requires the Yubikey or x509 password to be able to sign
the merged EFI executable.
This is the raw command; you might want to use `safeboot linux-sign` or
`safeboot recovery-sign` instead.
'

usage+=$install_kernel_usage
commands+="|install-kernel"

install-kernel() {

	TARGET="$1" ; shift

	if [ -z "$TARGET" ]; then
		echo "$sign_kernel_usage"
		exit 1
	fi

	OUTDIR="${EFIDIR}/${TARGET}"

	if [ ! -d "$OUTDIR" ]; then
		echo "$OUTDIR: Creating directory on EFI System Partition"
		mkdir -p "$OUTDIR" 
	fi

	if ! efibootmgr | grep "^Boot.* $TARGET\$" ; then
		# determine the device the EFI system partition is on
		DEV="$(df "$OUTDIR" | tail -1 | cut -d' ' -f1)"
		part=$(cat /sys/class/block/$(basename $DEV)/partition)

		echo "$OUTDIR: Creating boot menu item on $DEV, partition $part"
		efibootmgr \
			--quiet \
			--create \
			--disk "$DEV" \
			--part $part \
			--label "$TARGET" \
			--loader "\\EFI\\$TARGET\\linux.efi" 
	fi

	if [ $# == 0 ]; then
		echo "Using /proc/cmdline"
		cat /proc/cmdline > "$TMP/cmdline.txt"
	else
		echo -n "$@" > "$TMP/cmdline.txt"
	fi

	echo "Kernel commandline: '$(cat "$TMP/cmdline.txt")'"


	echo "Creating unified linux image"
	objcopy \
	    --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \
	    --add-section .cmdline="$TMP/cmdline.txt" --change-section-vma .cmdline=0x30000 \
	    --add-section .splash="/home/vxadmin/votingworks.png" --change-section-vma .splash=0x40000 \
	    --add-section .linux="/boot/vmlinuz" --change-section-vma .linux=0x2000000 \
	    --add-section .initrd="/boot/initrd.img" --change-section-vma .initrd=0x3000000 \
	    "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" "${TMP}/linux.efi"

	echo "Signing unified linux image"
	mkdir -p /boot/efi/EFI/linux
	sbsign --key "signing.key" --cert "cert.pem" --output "/boot/efi/EFI/linux/linux-signed.efi" $TMP/linux.efi

	echo "Updating boot manager with new image"
	# remove old linux
	efibootmgr -B -b 3 || echo "No previous entry"

	efibootmgr --create --disk "/dev/nvme0n1p1" --part "1" --label "linux" --loader "\\EFI\\linux\\linux-signed.efi"

}

remount_ro()
{
	rootdev-check -

	DEV="${1:-${ROOTDEV}}"
	KILLALL="$2"

	if [ "$(blockdev --getro "${DEV}")" == 1 ] ; then
		echo "${DEV}: already read-only"
		return 0
	fi

	# systemd often ends up holding an open file, so tell init
	# to reload its status
	telinit u

	echo "${DEV}: remounting read-only"
	if mount -o ro,noatime,remount "${DEV}" ; then

		echo "${DEV}: forcing fsck"
		fsck.ext4 -f "${DEV}" \
			|| die "${DEV}: Could not fsck"

		echo "${DEV}: setting block dev readonly"
		blockdev --setro "${DEV}" \
			|| die "${DEV}: Could not set read-only"

		return 0
	fi

	echo "${DEV}: something blocked remount. Likely processes:"
	lsof +f -- "${DEV}" 2>&- \
		| awk '$4 == "DEL" || $4 ~ /[0-9][uw]$/ { print $2, $1, $3, "("$4")" }' \
		| tee "$TMP/pid.lst" \
	|| echo "lsof failed"


	if [ "$KILLALL" = "killall" ]; then
		echo "KILLING ALL PROCESSES in 5 seconds"
		sleep 5
		awk '{print $1}' "$TMP/pid.lst" | xargs kill
	else
		echo "Re-run 'safeboot remount ro killall' to kill processes"
	fi

	return 1
}


linux-sign
