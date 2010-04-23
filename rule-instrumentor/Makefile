ASPECTATOR_DIR = aspectator
ASPECTATOR_PATH = aspectator/llvm-2.6

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

# Phony targets.
.PHONY: all install test clean

# Building, testing and cleaning aren't needed for rule-instrumentor itself. Just for subdirectories.
all:
	cd $(ASPECTATOR_PATH) || exit 1; $(MAKE) $@ || exit 1

test:
	cd $(ASPECTATOR_PATH) || exit 1; $(MAKE) $@ || exit 1

clean:
	cd $(ASPECTATOR_PATH) || exit 1; $(MAKE) $@ || exit 1

# Install needed executables to specified path.
install:
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir) || exit 1; fi
	if [ ! -d $(mandir) ]; then mkdir -p $(mandir) || exit 1; fi
	cp $(RULE_INSTRUMENTOR_SCRIPT) $(bindir) || exit 1
	if [ -d $(RULE_INSTRUMENTOR_SCRIPT) ] ; then cp -r $(RULE_INSTRUMENTOR_DIR) $(prefix) || exit 1 ; fi
	export prefix="$(prefix)/$(RULE_INSTRUMENTOR_DIR)/$(ASPECTATOR_DIR)" || exit 1; cd $(ASPECTATOR_PATH) || exit 1; $(MAKE) $@ || exit 1
