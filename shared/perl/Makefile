# Compilation
# (Perl modules don't require installation

# Installation
# Perl modules config
perl_modules=File/Copy/Recursive.pm StreamAutomaton.pm LDV/Utils.pm Utils.pm File/Cat.pm error-trace-visualizer/Entity.pm error-trace-visualizer/Annotation.pm error-trace-visualizer/CPAchecker.pm Text/Highlight.pm Text/Highlight/CPP.pm MetaUtils.pm \
	DSCV/RCV/Utils.pm \
	DSCV/RCV/Library.pm \


perl_src_dir=modules

# Modules that need to be compiled
perl_compiled_modules=Proc/Wait3
perl_compiled_src_dir=compiled_modules

perl_all_modules=$(perl_modules)
	# No compiled modules here -- tracked elsewhere
perl_install_dir=$(prefix)/shared/perl
perl_targets=$(patsubst %,$(perl_install_dir)/%,$(perl_all_modules))

# Compiled modules machinery
# Compiled modules have the following steps:
# 	1. Genereate Makefile from Makefile.PL
# 	2. Invoke make
# 	3. Copu files on install stage
compile_modules=$(perl_compiled_modules:%=%)
prepare_module=$(perl_compiled_src_dir)/$1/Makefile
compile_module=$(perl_compiled_src_dir)/$1-compile
install_module=$(perl_compiled_src_dir)/$1-install

$(call prepare_module,%): $(call prepare_module,%).PL
	cd $(@D) && perl Makefile.PL

$(call compile_module,%): $(call prepare_module,%)
	@$(MAKE) -C $(perl_compiled_src_dir)/$*

$(call install_module,%): $(call compile_module,%)
	@mkdir -p $(perl_install_dir)/auto/$*
	cp -rf $(perl_compiled_src_dir)/$*/blib/arch/auto/$*/* $(perl_install_dir)/auto/$*/
	@mkdir -p $(perl_install_dir)/$*
	cp -rf $(perl_compiled_src_dir)/$*/blib/lib/$*.pm $(perl_install_dir)/$*.pm


# Usual targets
all: $(foreach mod,$(perl_compiled_modules),$(call compile_module,$(mod)))

install: $(perl_targets) $(foreach mod,$(perl_compiled_modules),$(call install_module,$(mod)))

clean:

$(perl_install_dir)/%: $(perl_src_dir)/%
	@mkdir -p $(@D)
	cp $^ $@

