
# Compilation
all: rcv-subdir-all
	@echo DSCV doesn\'t require compilation

# Installation
export dscv_install_dir=$(prefix)/dscv
bindir?=$(prefix)/bin
dscv_target=$(bindir)/dscv

install: rcv-subdir-install $(dscv_target)

clean: rcv-subdir-clean

$(dscv_target): dscv
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@
	
define mksubdir
$1-subdir-%:
	$$(MAKE) -C $1 $$*
endef

$(eval $(call mksubdir,rcv))


