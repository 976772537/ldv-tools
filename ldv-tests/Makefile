INSTALL_DIR = __install

TEST_DIRS = integration-testing rule-models regr-tests commit-tests

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

# Building, testing, cleaning and installation aren't needed for ldv-tests themselves. Just for subdirectories.
all:
	for test_dir in $(TEST_DIRS); do $(MAKE) -C $$test_dir $@; done

test:
	for test_dir in $(TEST_DIRS); do $(MAKE) -C $$test_dir $@; done

clean:
	for test_dir in $(TEST_DIRS); do $(MAKE) -C $$test_dir $@; done

install:
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir) || exit 1; fi
	if [ ! -d $(mandir) ]; then mkdir -p $(mandir) || exit 1; fi
	for test_dir in $(TEST_DIRS); do $(MAKE) -C $$test_dir $@; done
