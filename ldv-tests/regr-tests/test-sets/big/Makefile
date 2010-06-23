INSTALL_DIR = __install

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

all:

test:

clean:

install:
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir) || exit 1; fi
	if [ ! -d $(mandir) ]; then mkdir -p $(mandir) || exit 1; fi
