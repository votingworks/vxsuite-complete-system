checkout:
	git pull --rebase
	git submodule update --init

node:
	sudo apt install -y curl
	bash ./setup-node.sh

deps: node
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
