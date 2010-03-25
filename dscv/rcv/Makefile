
# Configuration
backends=blast
frontends=$(backends)

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
	
define mksubdir
$1-subdir-%:
	prefix=$(rcv_install_dir)/$1 $$(MAKE) -C $1 $$*

endef

# Create subdir wrappers for backends
$(foreach backend,$(backends),$(eval $(call mksubdir,backends/$(backend))))


