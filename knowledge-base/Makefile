INSTALL_DIR = __install

KB_RECALC_SCRIPT = kb-recalc.pl

KB_DIR = knowledge-base

KB_SCHEMA = kb.sql
KB_COMMON_DATA = kb-common.sql

# Standard Makefile section.
# Use root installation directory if no prefix was specified. 
ifndef prefix
prefix = `readlink -f $(INSTALL_DIR)`
endif
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
mandir = ${prefix}/man

# Phony targets.
.PHONY: all install test clean

# Default make action.
all:
	@echo The knowledge base (re)generator doesn\'t require compilation

# Install needed executables to specified path.
install:
	mkdir -p $(bindir)
	mkdir -p $(mandir)
	cp $(KB_RECALC_SCRIPT) $(bindir)
	mkdir -p "$(prefix)/$(KB_DIR)"
	cp $(KB_SCHEMA) $(KB_COMMON_DATA) $(prefix)/$(KB_DIR)

test:
	@echo The knowledge base (re)generator doesn\'t have any test

clean:
	@echo The knowledge base (re)generator doesn\'t require cleaning 