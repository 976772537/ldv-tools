INSTALL_DIR = __install

TEST_TASK = regr-task-small

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

SMALL_TEST_DIR = ldv-tests/regr-tests/test-sets/small/
TMP_DIR_DRV = __install_drivers
TMP_DIR_KERN = __install_kernels

# Compilation
all: 
	../general/pack-drivers.sh ${TMP_DIR_DRV} || exit 1
	./prepare-kernels.sh ${TMP_DIR_KERN} || exit 1 

# Installation
define test_prefix
        if [ ! -n "$(prefix)" ]; then echo "please specify prefix"; exit 1; fi
endef

install: all 
	@$(call test_prefix)
	if [ ! -d $(prefix)/$(SMALL_TEST_DIR) ]; then mkdir -p $(prefix)/$(SMALL_TEST_DIR) || exit 1; fi
	cp -r ${TMP_DIR_DRV}/*.tar.bz2 $(prefix)/$(SMALL_TEST_DIR) || exit 1;
	cp -r ${TMP_DIR_DRV}/*.diff $(prefix)/$(SMALL_TEST_DIR) || exit 1;
	cp -r ${TMP_DIR_KERN}/*.tar.bz2 $(prefix)/$(SMALL_TEST_DIR) || exit 1;
	cp $(TEST_TASK) $(prefix)/$(SMALL_TEST_DIR) || exit 1;	
	cp regr-test-small-* $(prefix)/$(SMALL_TEST_DIR) || exit 1;	

# Clean
clean: 
	@$(call test_prefix)
	rm -r ${TMP_DIR_DRV} || exit 1
	rm -r ${TMP_DIR_KERN} || exit 1
