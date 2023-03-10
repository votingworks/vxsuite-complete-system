checkout:
	git pull --rebase
	git submodule update --init

node:
	sudo apt install -y curl
	bash ./setup-node.sh

rust:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

add-ppa:
	apt-cache search --names-only "^python3.9$$" | grep python || sudo add-apt-repository -y ppa:deadsnakes/ppa # add deadsnakes only if we need to

install-python: add-ppa
	sudo apt install -y python3.9 python3.9-dev python3.9-distutils python3-pip

install-smartcard:
	sudo apt install -y libusb-1.0-0-dev libpcsclite-dev pcscd pcsc-tools swig

deps: node rust install-python install-smartcard
	sudo apt install -y build-essential rsync cups cryptsetup efitools #debian
	sudo apt install -y libx11-dev

build-kiosk-browser:
	make -C kiosk-browser install
	make -C kiosk-browser build
	bash ./package-kiosk-browser.sh

build: build-kiosk-browser deps
	bash ./build.sh all

clean:
	git clean -dfx
	git submodule foreach git clean -dfx
