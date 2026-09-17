checkout:
	git pull --rebase
	git submodule update --init

clean:
	git clean -dfx
	git submodule foreach git clean -dfx
