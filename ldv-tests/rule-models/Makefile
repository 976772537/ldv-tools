INSTALL_DIR = __install

TEST_TASK = regr-task-models

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

MODEL_TEST_DIR = ldv-tests/rule-models/
TMP_DIR_DRV = __install_drivers

# Compilation
all: 
	../regr-tests/test-sets/general/pack-drivers.sh ${TMP_DIR_DRV} || exit 1

# Installation
define test_prefix
        if [ ! -n "$(prefix)" ]; then echo "please specify prefix"; exit 1; fi
endef

install: all 
	@$(call test_prefix)
	if [ ! -d $(prefix)/$(MODEL_TEST_DIR) ]; then mkdir -p $(prefix)/$(MODEL_TEST_DIR) || exit 1; fi
	cp -r ${TMP_DIR_DRV}/*.tar.bz2 $(prefix)/$(MODEL_TEST_DIR) || exit 1;
	cp $(TEST_TASK) $(prefix)/$(MODEL_TEST_DIR) || exit 1;	
	cp ../regr-tests/test-sets/big/linux-2.6.31.6.tar.bz2 $(prefix)/$(MODEL_TEST_DIR) || exit 1;
# Clean
clean: 
	@$(call test_prefix)
	rm -r ${TMP_DIR_DRV} || exit 1
	rm -r ${TMP_DIR_KERN} || exit 1
