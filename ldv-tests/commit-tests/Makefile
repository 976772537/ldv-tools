INSTALL_DIR = __install

# Scripts for commit testing.
COMMIT_TEST = commit-test.pl
COMMIT_TEST_UPLOAD = commit-upload.pl
COMMIT_TEST_LOAD = commit-load.pl
COMMIT_TEST_CONFIG_DIR=configs
COMMIT_TESTER_CONCAT = commit-tester-report.pl

# LDV tests directory.
LDV_TEST_DIR = ldv-tests

# Commit tests directory.
COMMIT_TEST_DIR = commit-tests

# Standard Makefile section.
# Use root installation directory if no prefix was specified.
ifndef prefix
prefix = `readlink -f $(INSTALL_DIR)`
endif
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin

# Phony target.
.PHONY: all install

all:
	@echo "Nothing to do"

install:
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir) || exit 1; fi
	cp $(COMMIT_TEST) $(bindir) || exit 1;
	if [ ! -d $(prefix)/$(LDV_TEST_DIR)/$(COMMIT_TEST_DIR) ]; then mkdir -p $(prefix)/$(LDV_TEST_DIR)/$(COMMIT_TEST_DIR) || exit 1; fi
	cp $(COMMIT_TEST_UPLOAD) $(COMMIT_TESTER_CONCAT) $(COMMIT_TEST_LOAD) $(prefix)/$(LDV_TEST_DIR)/$(COMMIT_TEST_DIR) || exit 1
	cp -r $(COMMIT_TEST_CONFIG_DIR) $(prefix)/$(LDV_TEST_DIR)/$(COMMIT_TEST_DIR) || exit 1
