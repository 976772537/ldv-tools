
# Compilation
#@echo kernel-rules doesn\'t require compilation

# Installation
KERNEL_RULES_DIR=kernel-rules
SRCDIR = .

define test_prefix
	if [ ! -n "$(prefix)" ]; then echo "please specify prefix"; exit 1; fi
endef

.PHONY: install clean

install: 
	@$(call test_prefix)
	if [ ! -d $(prefix)/$(KERNEL_RULES_DIR) ]; then mkdir -p $(prefix)/$(KERNEL_RULES_DIR); fi
	$(SRCDIR)/install  $(prefix)/$(KERNEL_RULES_DIR)

clean: 
	@$(call test_prefix)
	rm -fr $(prefix)/$(KERNEL_RULES_DIR)

