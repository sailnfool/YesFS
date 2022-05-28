.PHONY: all func scripts
.ONESHELL:
all: scripts func
scripts:
	cd scripts
	make uninstall install clean
	cd ..
func:
	cd func
	make uninstall linstall clean
	cd ..
