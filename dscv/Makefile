
# Compilation
all: rcv-subdir-all
	@echo DSCV doesn\'t require compilation

# Installation
export dscv_install_dir=$(prefix)/dscv
bindir?=$(prefix)/bin
dscv_target=$(bindir)/dscv

# Perl modules config
perl_modules=File/Copy/Recursive.pm StreamAutomaton.pm DSCV/Sanity.pm
perl_src_dir=perl-shared
perl_install_dir=$(prefix)/shared/perl
perl_targets=$(patsubst %,$(perl_install_dir)/%,$(perl_modules))

install: rcv-subdir-install $(dscv_target) $(perl_targets)

clean: rcv-subdir-clean

$(perl_install_dir)/%: $(perl_src_dir)/%
	@mkdir -p $(@D)
	cp $^ $@

$(dscv_target): dscv
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@
	
define mksubdir
$1-subdir-%:
	$$(MAKE) -C $1 $$*
endef

$(eval $(call mksubdir,rcv))


