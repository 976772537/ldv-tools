ASPECTATOR_DIR = aspectator
# TODO: add key to optionally turn LLVM backend on
#aspectator_backends=llvm-2.6 gcc-4.6
aspectator_backends=gcc-4.6

INSTALL_DIR = __install

RULE_INSTRUMENTOR_DIR = rule-instrumentor
RULE_INSTRUMENTOR_SCRIPT = rule-instrumentor.pl

# Standard Makefile section.
# Use root installation directory if no prefix was specified.
ifndef prefix
prefix = `readlink -f $(INSTALL_DIR)`
endif
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
mandir = ${prefix}/man

# Template for making a target in a subdir (with prefix!)
define mksubdir
$1-subdir-%:
	prefix=$(prefix)/$(RULE_INSTRUMENTOR_DIR)/$1 $$(MAKE) -C $1 $$*

endef

# Phony targets.
.PHONY: all install test clean

# Building, testing and cleaning aren't needed for rule-instrumentor itself. Just for subdirectories.
all: $(patsubst %,$(ASPECTATOR_DIR)/%-subdir-all,$(aspectator_backends))
	@echo "Rule-instrumentor $@ finished"

test: $(patsubst %,$(ASPECTATOR_DIR)/%-subdir-test,$(aspectator_backends))
	@echo "Rule-instrumentor $@ finished"

clean: $(patsubst %,$(ASPECTATOR_DIR)/%-subdir-clean,$(aspectator_backends))
	@echo "Rule-instrumentor $@ finished"

# Install needed executables to specified path.
install: $(patsubst %,$(ASPECTATOR_DIR)/%-subdir-install,$(aspectator_backends))
	@mkdir -p $(bindir)
	@mkdir -p $(mandir)
	cp $(RULE_INSTRUMENTOR_SCRIPT) $(bindir) || exit 1

# Create rules for backends
$(foreach backend,$(aspectator_backends),$(eval $(call mksubdir,$(ASPECTATOR_DIR)/$(backend))))

