INSTALL_DIR = __install
BIG_TEST_DIR = ldv-tests/regr-tests/test-sets/big/
TEST_TASK = regr-task-big

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
	if [ ! -d $(prefix)/$(BIG_TEST_DIR) ]; then mkdir -p $(prefix)/$(BIG_TEST_DIR) || exit 1; fi
	cp -r *.tar.bz2 $(prefix)/$(BIG_TEST_DIR) || exit 1;
	cp $(TEST_TASK) $(prefix)/$(BIG_TEST_DIR) || exit 1;
	cp regr-test-big-* $(prefix)/$(BIG_TEST_DIR) || exit 1;

