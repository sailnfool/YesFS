.PHONY: all func scripts
.ONESHELL:
all: scripts yfunc
scripts:
	cd scripts
	make uninstall install clean
	cd ..
yfunc:
	cd yfunc
	make uninstall linstall clean
	cd ..
test:
	cd yfunc/tests
	make
	cd ../..
	cd tests
	make
	cd ..

