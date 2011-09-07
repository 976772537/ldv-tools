
# Compilation
all: rcv-subdir-all
	@echo DSCV doesn\'t require compilation

# Installation
export dscv_install_dir=$(prefix)/dscv
bindir?=$(prefix)/bin
dscv_target=$(bindir)/dscv

install: rcv-subdir-install $(dscv_target) $(dscv_install_dir)/rcv-launcher

clean: rcv-subdir-clean

$(dscv_target): dscv
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@
	
$(dscv_install_dir)/rcv-launcher: rcv-launcher
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@

define mksubdir
$1-subdir-%:
	$$(MAKE) -C $1 $$*
endef

$(eval $(call mksubdir,rcv))


# Place to install unit tests is controlled by $(prefix) variable, so we can re-use existing targets
unit-tests: $(dscv_target) rcv-subdir-mockinstall $(bindir)/dscv-unit-tests-run $(bindir)/fake-rule-instrumentor.pl
	export PATH=$(bindir):$(PATH) ; test_src_dir=$(abspath unit-tests/tests) dscv-unit-tests-run
	@echo ALL TESTS PASSED

$(bindir)/dscv-unit-tests-run: unit-tests/run
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@

$(bindir)/fake-rule-instrumentor.pl: unit-tests/ri
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@



