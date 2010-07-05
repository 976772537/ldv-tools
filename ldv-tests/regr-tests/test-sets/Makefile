INSTALL_DIR = __install

TEST_DIRS = small medium big

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

# Building, testing, cleaning and installation aren't needed for test sets themselves. Just for subdirectories.
all:
	for test_dir in $(TEST_DIRS); do cd $$test_dir || exit 1; $(MAKE) $@ || exit 1; done

test:
	for test_dir in $(TEST_DIRS); do cd $$test_dir || exit 1; $(MAKE) $@ || exit 1; done

clean:
	for test_dir in $(TEST_DIRS); do cd $$test_dir || exit 1; $(MAKE) $@ || exit 1; done

install:
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir) || exit 1; fi
	if [ ! -d $(mandir) ]; then mkdir -p $(mandir) || exit 1; fi
	export cwd=$(PWD); for test_dir in $(TEST_DIRS); do cd "$$cwd/$$test_dir" || exit 1; $(MAKE) $@ || exit 1; done