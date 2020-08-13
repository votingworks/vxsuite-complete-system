
FRONTENDS := $(wildcard frontends/*)
COMPONENTS := $(wildcard components/*)
CWD := $(shell pwd)

checkout:
	git pull
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
	sudo dpkg -i kiosk-browser/out/make/deb/x64/kiosk-browser_*_amd64.deb

build: build-kiosk-browser patch
	$(foreach component, $(COMPONENTS), \
		make -C $(component) install; \
		PIPENV_VENV_IN_PROJECT=1 make -C $(component) build; \
	)
	$(foreach frontend, $(FRONTENDS), \
		PIPENV_VENV_IN_PROJECT=1 make -C $(frontend) build; \
	)

