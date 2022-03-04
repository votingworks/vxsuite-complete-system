UNAME=$(uname -m)

if [[ $UNAME == "aarch64" ]]; then
	sudo dpkg -i kiosk-browser/out/make/deb/arm64/kiosk-browser_*_arm64.deb
else
	sudo dpkg -i kiosk-browser/out/make/deb/x64/kiosk-browser_*_amd64.deb
fi
