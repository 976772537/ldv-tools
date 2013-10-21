INSTALL_DIR = __install

TEST_TASK = regr-task-aspect

# Standard Makefile section.

exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
mandir = ${prefix}/man

# Phony targets.
.PHONY: all install test clean

ASPECT_TEST_DIR = ldv-tests/aspect-tests/
TMP_DIR_DRV = __install_drivers
PACK_SCRIPT = ../regr-tests/test-sets/general/pack-drivers.sh
# Compilation
all: 
	${PACK_SCRIPT} ${TMP_DIR_DRV} || exit 1

# Installation
define test_prefix
        if [ ! -n "$(prefix)" ]; then echo "please specify prefix"; exit 1; fi
endef

install: 
	@$(call test_prefix)
	if [ ! -d $(prefix)/$(ASPECT_TEST_DIR) ]; then mkdir -p $(prefix)/$(ASPECT_TEST_DIR) || exit 1; fi
	cp -r ${TMP_DIR_DRV}/*.tar.bz2 $(prefix)/$(ASPECT_TEST_DIR) || exit 1;
	cp $(TEST_TASK) $(prefix)/$(ASPECT_TEST_DIR) || exit 1;	
	cp ../regr-tests/test-sets/big/linux-2.6.32.15.tar.bz2 $(prefix)/$(ASPECT_TEST_DIR) || exit 1;	

# Clean
clean: 
	rm -r ${TMP_DIR_DRV} || exit 1
