
SHELL=/bin/bash
PREFIX?=$(HOME)
.sh:
	@rm -f $@
	cp $< $@

EXECDIR := $(PREFIX)/bin

.PHONY: clean uninstall all
all: 
	cd scripts ;make uninstall install clean
install: $(INSTALL)
	mkdir -p $(EXECDIR)
	install -o $(USER) -C $? $(EXECDIR)
clean: 
	@for execfile in $(INSTALL); do \
		echo rm -f $$execfile; \
		rm -f $$execfile; \
	done
uninstall: 
	@for execfile in $(INSTALL); do \
		echo rm -f $(EXECDIR)/$$execfile; \
		rm -f $(EXECDIR)/$$execfile; \
	done
$(EXECDIR):
	mkdir -p $(EXECDIR)
