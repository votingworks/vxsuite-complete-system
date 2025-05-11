checkout:
	git pull --rebase
	git submodule update --init

build: bash ./build.sh all

clean:
	git clean -dfx
	git submodule foreach git clean -dfx
