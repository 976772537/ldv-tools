INSTALL_DIR = __install

# Paths to binaries relatively to installation directory.
BINDIR_ASPECTATOR = aspectator

# File that contains statistics server variables defined by user.
CONFIG = config

# Standard Makefile section.
# Use root installation directory if no prefix was specified. 
ifndef prefix
prefix = `readlink -f $(INSTALL_DIR)`
endif
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
mandir = ${prefix}/man

# Paths to binaries symlinks relatively to bindir.
BIN_COMPILER = compiler

# Phony targets.
.PHONY: all install test clean

# Default make action.
all:
	@echo The statistics server doesn\'t require compilation

# Install needed files to specified paths.
install:
	if [ -f $(CONFIG) ]; then cat $(CONFIG) || exit 1; fi

test:
	@echo The statistics server doesn\'t have any test

clean:
	@echo The statistics server doesn\'t require cleaning
