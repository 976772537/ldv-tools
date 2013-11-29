
# Configuration
ifeq ($(no_blast),)
backends=blast
else
backends=
endif
frontends=blast cpachecker ufo cbmc

# PTRSAFE
ifneq ($(LDV_PTRSAFE),)
backends+=ptrsafe
frontends+=ptrsafe
endif

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

$(rcv_install_dir)/ufo: ufo
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@

$(rcv_install_dir)/ptrsafe: ptrsafe
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@

$(rcv_install_dir)/cbmc: cbmc
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
# We copy all files in cpachecker.config directory into $(rcv_install_dir)/etc
# Then we check that $(rcv_install_dir)/etc contains critical files,
# namely `default.properties' and `LDVErrorLabel.spc'
cpachecker_src_confdir=cpachecker.config
cpachecker_dst_confdir=$(rcv_install_dir)/etc
cpachecker_config_files:=$(patsubst $(cpachecker_src_confdir)/%,$(cpachecker_dst_confdir)/%,$(wildcard $(cpachecker_src_confdir)/*))

cpachecker_critical_files_list= \
		default.properties \
		LDVErrorLabel.spc \

cpachecker_critical_files=$(patsubst %,$(cpachecker_dst_confdir)/%,$(cpachecker_critical_files_list))
install: $(cpachecker_config_files) $(cpachecker_critical_files) $(cil)

$(cpachecker_dst_confdir)/%: $(cpachecker_src_confdir)/%
	@mkdir -p $(@D)
	cp $^ $@

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


ifeq ($(no_cpachecker),)

# Configuring and installing CPAchecker
cpachecker_dir=backends/cpachecker
cpachecker_target=$(rcv_install_dir)/backends/cpachecker/
cpachecker_tmp=$(rcv_install_dir)/backends/tmp/
cpachecker_dist=CPAchecker-1.2-svn-unix
cpachecker_tar=$(cpachecker_dist).tar.bz2

# CPAchecker compilation
.PHONY: cpachecker-build

cpachecker-build: 
	cd $(cpachecker_dir) && ant tar

# Installation of CPAchecker submodule

cpachecker-install:
	@mkdir -p $(cpachecker_tmp)
	tar xfj $(cpachecker_dir)/$(cpachecker_tar) -C $(cpachecker_tmp)
	rm -rf $(cpachecker_target)
	mv $(cpachecker_tmp)/$(cpachecker_dist) $(cpachecker_target)
	rmdir $(cpachecker_tmp)

install: cpachecker-install

all: cpachecker-build

endif
