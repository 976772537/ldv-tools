STATS_SERVER_DIR = stats
STATS_SERVER_MAN = stats-server

SCRIPTS = $(shell find ${STATS_SERVER_DIR} -type f)

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
	@echo statistics server doesn't require compilation

test:
	@echo statistics server doesn't contain any test

clean:
	@echo statistics server doesn't require cleaning

# Install needed executables to specified path.
install: $(SCRIPTS)
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir) || exit 1; fi
	if [ ! -d $(mandir) ]; then mkdir -p $(mandir) || exit 1; fi
	if [ ! -d $(confdir) ]; then mkdir -p $(confdir) || exit 1; fi
	cp -r $(STATS_SERVER_DIR) $(prefix) || exit 1
	cp $(STATS_SERVER_MAN) $(mandir) || exit 1