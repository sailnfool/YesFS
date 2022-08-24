SHELL=/bin/bash
PREFIX?=$(HOME)
LPREFIX?=$(HOME)/.local
.sh:
	@rm -f $@
	cp $< $@
LINSTALL = yfunc.create_canonical \
	yfunc.create_spec_backref \
	yfunc.maketop \
	yfunc.hashdirpath \
	yfunc.create_spec_backref \
	yfunc.put_first_backref \
	yfunc.put_nhid 


EXECDIR := $(PREFIX)/bin
LEXECDIR := $(LPREFIX)/bin

.PHONY: clean linstall uninstall all
all: $(LINSTALL)
	make uninstall linstall

# install: $(INSTALL)
# 	mkdir -p $(EXECDIR)
# 	install -o $(USER) -C $? $(EXECDIR)
# 	rm -f $?
linstall: $(LINSTALL)
	mkdir -p $(LEXECDIR)
	install -o $(USER) -c $? $(LEXECDIR)
	rm -f $?
clean:
	@for execfile in $(LINSTALL); do \
		echo rm -f $$execfile; \
		rm -f $$execfile; \
	done

uninstall:
	@for execfile in $(LINSTALL); do \
		echo rm -f $(EXECDIR)/$$execfile; \
		rm -f $(EXECDIR)/$$execfile; \
	done

$(EXECDIR):
	mkdir -p $(EXECDIR)
$(LECEVDIR):
	mkdir -p $(LEXECDIR)
