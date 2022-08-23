SHELL=/bin/bash
PREFIX?=$(HOME)
LPREFIX?=$(HOME)/.local
.sh:
	@rm -f $@
	cp $< $@
LINSTALL = yfunc.global \
	yfunc.maketop
# 	yfunc.create_canonical \
# 	yfunc.hashdirpath \
# 	yfunc.put_backr\
# 	yfunc.put_chunk \
# 	yfunc.put_first_backref \
# 	yfunc.put_mani \
# 	yfunc.put_namemeta \
# 	yfunc.put_nhid \


EXECDIR := $(PREFIX)/bin
LEXECDIR := $(LPREFIX)/bin

#.PHONY: clean linstall uninstall all
all: $(LINSTALL)
	make uninstall linstall

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
