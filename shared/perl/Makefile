# Compilation
# (Perl modules don't require installation
all: 

# Installation
# Perl modules config
perl_modules=File/Copy/Recursive.pm StreamAutomaton.pm DSCV/Sanity.pm LDV/Utils.pm DSCV/RCV/Utils.pm Utils.pm File/Cat.pm
perl_src_dir=modules
perl_install_dir=$(prefix)/shared/perl
perl_targets=$(patsubst %,$(perl_install_dir)/%,$(perl_modules))

install: $(perl_targets)

clean:

$(perl_install_dir)/%: $(perl_src_dir)/%
	@mkdir -p $(@D)
	cp $^ $@

