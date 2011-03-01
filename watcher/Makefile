
# Compilation
all:
	@echo Watcher doesn\'t require compilation

# Installation
export install_dir=$(prefix)/watcher
bindir?=$(prefix)/bin
dscv_target=$(bindir)/dscv

targets=ldv-watcher generic.rb local.rb

watcher_targets=$(targets:%=$(install_dir)/%)

install: $(watcher_targets)

clean:

$(install_dir)/%: %
	@mkdir -p $(@D)
	cp -f -p $^ $@

define mksubdir
$1-subdir-%:
	$$(MAKE) -C $1 $$*
endef

