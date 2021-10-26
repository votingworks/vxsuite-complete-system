The scripts in this folder help setup a secure booting environment for VotingWorks systems. It is still a work in progress. 

Instructions:

Note: All of the below instructions assume you're in the same directory (I used `/home/vxadmin`)

1. Install Ubuntu with the following partitioning scheme (no LVM or LUKS!)
- 512MB for the EFI system partition
- no more than 16GB for the root partition mounted on `/`
- 80GB for `/var`
- 1GB for a partition called `/hashes`, where the dm-verty hashes will live
- The rest of the disk for `/home`
2. Install all the dependencies TODO: script forthcoming
3. Run `keys-init.sh` to generate the signing key used to generate Secure Boot keys and sign kernel images
4. Run `install-keys.sh` to generate new Secure Boot keys and persist them in firmware
5. Run `mkrecovery.sh` to create a recovery image that will be necessary to setup dm-verity
6. Modify `/etc/fstab` to mark root partition readonly and set secure options on the other partitions TODO: script this
7. Remove /tmp and recreate it as a symbolic link to `/var/tmp`
8. Reboot into the recovery kernel and choose "root" on the menu
9. Run `mklinux.sh` to compute a dmverity hash and generate a unified EFI boot executable that is signed by the keys
10. Reboot, now you should be in a secure state! Setup TPM-TOTP: `sudo tpm2-totp --pcrs=0,2,4,5,7 init`
