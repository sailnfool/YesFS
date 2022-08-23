.PHONY: all linstall
.ONESHELL:
all: linstall
linstall:
	cd scripts
	make uninstall linstall
	cd ..
uninstall:
	cd scripts
	make uninstall clean
	cd ..
clean:
	cd scripts
	make clean
	cd ..
test:
	cd tests
	make
	cd ..
