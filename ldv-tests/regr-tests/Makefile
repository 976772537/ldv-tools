INSTALL_DIR = __install

TEST_SETS_DIR = test-sets

# Scripts for regression testing.
REGR_TEST = regr-test.pl
REGR_TEST_WRAPPER = ldv-test
REGR_TEST_LAUNCH = launch.pl
REGR_TEST_UPLOAD = upload.pl
REGR_TEST_CHECK = check.pl

# LDV tests directory. It's relative to the prefix.
LDV_TEST_DIR = ldv-tests

# Regression tests directory. It's relative to the LDV tests directory.
REGR_TEST_DIR = regr-tests

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

# Building, testing and cleaning aren't needed for regression tests themselves. Just for subdirectories.
all:
	cd $(TEST_SETS_DIR) || exit 1; $(MAKE) $@ || exit 1

test:
	cd $(TEST_SETS_DIR) || exit 1; $(MAKE) $@ || exit 1

clean:
	cd $(TEST_SETS_DIR) || exit 1; $(MAKE) $@ || exit 1

install:
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir) || exit 1; fi
	if [ ! -d $(mandir) ]; then mkdir -p $(mandir) || exit 1; fi
	cp $(REGR_TEST) $(bindir) || exit 1;
	cp -f $(REGR_TEST_WRAPPER) $(bindir)
	if [ ! -d $(prefix)/$(LDV_TEST_DIR)/$(REGR_TEST_DIR) ]; then mkdir -p $(prefix)/$(LDV_TEST_DIR)/$(REGR_TEST_DIR) || exit 1; fi
	cp $(REGR_TEST_LAUNCH) $(REGR_TEST_UPLOAD) $(REGR_TEST_CHECK) $(prefix)/$(LDV_TEST_DIR)/$(REGR_TEST_DIR) || exit 1
	cd $(TEST_SETS_DIR) || exit 1; $(MAKE) $@ || exit 1
