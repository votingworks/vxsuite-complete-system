checkout:
	git pull --rebase
	git submodule update --init

node:
	sudo apt install -y curl
	bash ./setup-node.sh

# FIXME: these things should be installed by their respective packages
patch:
	sudo apt install -y libx11-dev

build-kiosk-browser:
	make -C kiosk-browser install
	make -C kiosk-browser build
	bash ./package-kiosk-browser.sh

build: build-kiosk-browser patch
	bash ./build.sh all

clean:
	git clean -dfx
	git submodule foreach git clean -dfx
