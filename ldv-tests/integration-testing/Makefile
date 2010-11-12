# Scripts for integration testing.
INTEGR_TEST_CHECK_DB = checkdb.pl
IT_LOAD_SRC = load-src.pl

# LDV tests directory. It's relative to the prefix.
LDV_TEST_DIR = ldv-tests

# Regression tests directory. It's relative to the LDV tests directory.
INTEGR_TEST_DIR = integration-testing

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
	@echo "ok";

test:
	@echo "ok";

clean:
	@echo "ok";

install:
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir) || exit 1; fi
	if [ ! -d $(prefix)/$(LDV_TEST_DIR)/$(INTEGR_TEST_DIR) ]; then mkdir -p $(prefix)/$(LDV_TEST_DIR)/$(INTEGR_TEST_DIR) || exit 1; fi
	cp $(INTEGR_TEST_CHECK_DB) $(bindir) || exit 1;
	cp $(IT_LOAD_SRC) $(prefix)/$(LDV_TEST_DIR)/$(INTEGR_TEST_DIR) || exit 1;
