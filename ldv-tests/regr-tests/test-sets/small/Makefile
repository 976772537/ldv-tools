INSTALL_DIR = __install

# Standard Makefile section.
# Use root installation directory if no prefix was specified..
ifndef prefix
prefix = `readlink -f $(INSTALL_DIR)`
endif

exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
mandir = ${prefix}/man

# Phony targets.
.PHONY: all install test clean

SMALL_TEST_DIR=ldv-tests/regr-tests/test-sets/small/
TMP_DIR=__install_drivers

# Compilation
all: 
	./pack-drivers.sh ${TMP_DIR} || exit 1

# Installation
define test_prefix
        if [ ! -n "$(prefix)" ]; then echo "please specify prefix"; exit 1; fi
endef

install: all 
	@$(call test_prefix)
	if [ ! -d $(prefix)/$(SMALL_TEST_DIR) ]; then mkdir -p $(prefix)/$(SMALL_TEST_DIR) || exit 1; fi
	cp -r ${TMP_DIR}/* $(prefix)/$(SMALL_TEST_DIR) || exit 1;

# Clean
clean: 
	@$(call test_prefix)
	rm -r ${TMP_DIR} || exit 1
