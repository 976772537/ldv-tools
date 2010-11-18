
# Configuration
backends=blast
frontends=blast cpachecker

# Compilation
all: $(patsubst %,backends/%-subdir-all,$(backends))
	@echo RCV backends don\'t require compilation

# Installation
export rcv_install_dir=$(dscv_install_dir)/rcv
frontend_target=$(rcv_install_dir)/$1
backend_install_dir=$(rcv_install_dir)/backends/$1

install: $(patsubst %,backends/%-subdir-install,$(backends)) $(foreach frontend,$(frontends),$(call frontend_target,$(frontend)))

clean: $(patsubst %,backends/%-subdir-clean,$(backends))

$(rcv_install_dir)/blast: blast
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@

$(rcv_install_dir)/cpachecker: cpachecker
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@
	
define mksubdir
$1-subdir-%:
	prefix=$(rcv_install_dir)/$1 $$(MAKE) -C $1 $$*

endef

# Unit-testing
test_backends=mock

# First part of unit-testing subsystem is installing mock objects for DSCV
mockinstall: backends/mock-subdir-install $(call frontend_target,mock)

$(rcv_install_dir)/mock: mock
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@


.PHONY: mockinstall

# Create subdir wrappers for backends
all_backends=$(backends) $(test_backends)
$(foreach backend,$(all_backends),$(eval $(call mksubdir,backends/$(backend))))

# Install CPAchecker's configuration
cpachecker_confdir=$(rcv_install_dir)/etc
cpachecker_etcfiles= \
		cpa.cfg.pattern \
		errloc_automaton.txt \
		symbpredabsCPA.properties \

cpachecker_configs=$(patsubst %,$(cpachecker_confdir)/%,$(cpachecker_etcfiles))

install: $(cpachecker_configs) $(cil)

$(cpachecker_confdir)/%: cpachecker.config/%
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@


# Configuring and installing CIL
cil_dir=cil
cil_configured=$(cil_dir)/Makefile
cil_target=$(dscv_install_dir)/cil

# CIL compilation
$(cil_configured): $(cil_dir)/Makefile.in
	cd $(cil_dir) && ./configure

.PHONY: cil
cil: $(cil_configured)
	$(MAKE) -C $(cil_dir)

# Installation of CIL
tools_cil=$(cil_dir)/bin/CilConfig.pm $(cil_dir)/bin/cilly $(cil_dir)/obj/x86_LINUX/cilly.asm.exe $(shell find $(cil_dir)/lib -iname '*.pm')
cil_targets=$(tools_cil:$(cil_dir)/%=$(cil_target)/%)

# For cil tools to appear, we should compile CIL
$(tools_cil): cil

$(cil_target)/%: $(cil_dir)/%
	@mkdir -p $(@D)
	cp -L -r -f '$(cil_dir)/$*' '$@'

cil-install: $(cil_targets)


install: cil-install
all: cil

