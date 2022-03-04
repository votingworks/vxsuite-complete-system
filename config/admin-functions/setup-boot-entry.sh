efibootmgr \
	--create \
	--disk "$DEV" \
	--part $part \
	--label "VxLinux" \
	--loader "\\EFI\\debian\\VxLinux-signed.efi" \
