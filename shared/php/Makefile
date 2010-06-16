INSTALL_DIR = __install

LDV_SHARED_DIRNAME = shared
SHARED_PHP_DIRNAME = php
LDV_SHARED_PHP_DIRNAME = $(LDV_SHARED_DIRNAME)/$(SHARED_PHP_DIRNAME)

ZEND_LIBRARY = Zend

# Standard Makefile section.
# Use root installation directory if no prefix was specified..
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
	@echo The php shares doesn\'t require compilation

# Install needed files to specified paths.
install:
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir) || exit 1; fi
	if [ ! -d $(mandir) ]; then mkdir -p $(mandir) || exit 1; fi
	if [ ! -d $(prefix)/$(LDV_SHARED_PHP_DIRNAME) ]; then mkdir -p $(prefix)/$(LDV_SHARED_PHP_DIRNAME) || exit 1; fi
	cp -r $(ZEND_LIBRARY) $(prefix)/$(LDV_SHARED_PHP_DIRNAME) || exit 1

test:
	@echo The php shares doesn\'t have any test

clean:
	@echo The php shares doesn\'t require cleaning

