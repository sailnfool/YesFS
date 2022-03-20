SHELL=/bin/bash
PREFIX?=$(HOME)/.local
.sh:
	@rm -f $@
	cp $< $@
INSTALL = yfunc.create_spec_backref \
		yfunc.maketop \
	  yfunc.hashdirpath \
		yfunc.create_spec_backref \
		yfunc.put_first_backref \
		yfunc.put_nhid \
	  yfunc.global


EXECDIR := $(PREFIX)/bin

.PHONY: clean install uninstall all
all: $(INSTALL)
	make uninstall install

install: $(INSTALL)
	mkdir -p $(EXECDIR)
	install -o $(USER) -C $? $(EXECDIR)

clean: 
	@for execfile in $(INSTALL) ; do \
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
