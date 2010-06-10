SHELL=/bin/bash

all: cil
	@echo The "mock" RCV backend doesn\'t require compilation.

clean: ;

binaries=mock

cil_dir=cil-1.3.7
# Tools (for now, it's just CIL)
install_toolsdir=$(prefix)/tools
tools_cil=$(cil_dir)/bin/CilConfig.pm $(cil_dir)/bin/cilly $(shell find $(cil_dir)/obj -type f -executable) $(shell find $(cil_dir)/lib -iname '*.pm')
tools_target=$(tools_cil:$(cil_dir)/%=$(install_toolsdir)/cil/%)

# Copy command that resolves symlinks
inscp=cp -L -f

install: all $(patsubst %,$(prefix)/%,$(binaries)) $(tools_target)
	@echo MOCK installed to $(prefix)

# First rule for cil as it's more specific
$(install_toolsdir)/cil/%: $(cil_dir)/%
	mkdir -p $(@D)
	$(inscp) '$(cil_dir)/$*' '$@'


mock_bindir=$(prefix)
$(mock_bindir)/%: all
	@mkdir -p $(@D)
	$(inscp) $* $@
	@chmod +x $@

cil: 
	[ -f $(cil_dir)/Makefile ] || ( cd $(cil_dir) && ./configure )
	$(MAKE) -C $(cil_dir)


