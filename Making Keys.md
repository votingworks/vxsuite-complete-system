Now create the Secure boot keys:

```bash
su -
mkdir /etc/efi-keys
cd /etc/efi-keys
wget https://rodsbooks.com/efi-bootloaders/mkkeys.sh
chmod +x mkkeys.sh
./mkkeys.sh
```
For the common name, I usually enter "VotingWorks"

If you're in a VM, you can skip most of the secure boot steps (the following steps). Reboot the machine and enter into the BIOS setup. Find the Secure Boot screen and select an option like "delete all keys". This should put you into "Setup Mode". Now exit out of the firmware and boot the OS. From here, persist the keys you just generated to the firmware:
```bash
su -
cd /etc/efi-keys
efi-updatevar -f DB.auth DB
efi-updatevar -f KEK.auth KEK
efi-updatevar -f PK.auth PK
```
**IMPORTANT**: the order here matters. PK must be persisted _last_, otherwise it won't work. This should work well on Lenovo devices, but if it doesn't here is an alternate approach:

Copy the keys to the EFI system partition:
```bash
cp *.auth /boot/efi
```
Now reboot the machine and enter the firmware interface. On the Secure Boot screen, there should be an option to "Enroll Keys". It should show you your ESP on selection, at which point you can navigate to each of the three keys and enroll them in the firmware. As above, the order matters, so do DB, KEK then PK in that order.

At this point there should be keys enrolled in firmware and the machine should be in Secure Boot mode. You will probably have to turn it off for now so that we can still boot Debian, since we haven't signed anything yet. 

**IMPORTANT**: We are not using disk encryption, meaning that keys which are left on `/etc/efi-keys` or `/boot/efi` are **exposed**. The keys **must** be wiped from the disk before putting the machines in the field, preferably before cloning. 

