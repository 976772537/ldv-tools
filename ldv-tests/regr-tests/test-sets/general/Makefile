INSTALL_DIR = __install
GENERAL_TEST_DIR = ldv-tests/regr-tests/test-sets/general/
TEST_TASK = regr-task-general
TMP_DIR_DRV = __install_drivers

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

# Compilation
all:
	./pack-drivers.sh ${TMP_DIR_DRV} || exit 1

test:

# Clean
clean:
	rm -r ${TMP_DIR_DRV} || exit 1

# Installation
install: all
	if [ ! -d $(prefix)/$(GENERAL_TEST_DIR) ]; then mkdir -p $(prefix)/$(GENERAL_TEST_DIR) || exit 1; fi
	cp -r ${TMP_DIR_DRV}/*.tar.bz2 $(prefix)/$(GENERAL_TEST_DIR) || exit 1;
	cp $(TEST_TASK) $(prefix)/$(GENERAL_TEST_DIR) || exit 1;
	cp regr-task-kbdrivers $(prefix)/$(GENERAL_TEST_DIR) || exit 1;
	cp regr-test-general-* $(prefix)/$(GENERAL_TEST_DIR) || exit 1;
	cp ../big/linux-2.6.32.15.tar.bz2 $(prefix)/$(GENERAL_TEST_DIR) || exit 1;
	cp ../big/linux-2.6.31.6.tar.bz2 $(prefix)/$(GENERAL_TEST_DIR) || exit 1;


