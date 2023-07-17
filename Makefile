checkout:
	git pull --rebase
	git submodule update --init

build-kiosk-browser:
	make -C kiosk-browser install
	make -C kiosk-browser build
	bash ./package-kiosk-browser.sh

build: build-kiosk-browser 
	bash ./build.sh all

clean:
	git clean -dfx
	git submodule foreach git clean -dfx
