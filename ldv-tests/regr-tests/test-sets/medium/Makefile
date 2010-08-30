INSTALL_DIR = __install

# Standard Makefile section.
# Use root installation directory if no prefix was specified.
ifndef prefix
prefix = `readlink -f $(INSTALL_DIR)`
endif
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
mandir = ${prefix}/man

GENERAL_TEST_DIR = ldv-tests/regr-tests/test-sets/general/
MEDIUM_TEST_DIR = ldv-tests/regr-tests/test-sets/medium/
TEST_TASK = regr-task-medium

# Phony targets.
.PHONY: all install test clean

# Building, testing, cleaning and installation aren't needed for ldv-tests themselves. Just for subdirectories.
all:

test:

clean:

#general part should be installed before medium
install:
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir) || exit 1; fi
	if [ ! -d $(mandir) ]; then mkdir -p $(mandir) || exit 1; fi
	if [ ! -d $(prefix)/$(MEDIUM_TEST_DIR) ]; then mkdir -p $(prefix)/$(MEDIUM_TEST_DIR) || exit 1; fi
	cp $(prefix)/$(GENERAL_TEST_DIR)/*.tar.bz2 $(prefix)/$(MEDIUM_TEST_DIR) || exit 1;
	cat $(TEST_TASK) $(prefix)/$(GENERAL_TEST_DIR)/regr-task-general  $(prefix)/$(GENERAL_TEST_DIR)/regr-task-kbdrivers > $(prefix)/$(MEDIUM_TEST_DIR)/$(TEST_TASK) || exit 1;

