# Default target
all:
# Install shared ruby gems
ruby_gems=logging
# Install shared ruby scripts
ruby_scripts=ldv_logging.rb enhanced_open3.rb

gem_install_dir=$(prefix)/shared/ruby/gem
gem_bin_dir=$(prefix)/shared/ruby/bin
export GEM_HOME=$(gem_install_dir)
gem_src=gems

script_install_dir=$(prefix)/shared/ruby/lib
script_src=lib

# Command to install gem
ifndef GEM_DOC
no_rdoc=--no-rdoc
endif
Gem_install=gem install --install-dir $(gem_install_dir) --bindir $(gem_bin_dir) $(no_rdoc) --no-ri

# Compile gems
ifndef NO_GEMS
all: gems-compile
install: gems-install
else
all:
install:
endif

# Some gem _build_ scripts rely on rubygems
export RUBYOPT=rubygems

gems-compile: $(foreach gem,$(ruby_gems),$(gem)-compile) ;
gems-install: $(foreach gem,$(ruby_gems),$(gem)-install) ;

# Gem-specific commands.  To add commands for your gem, add gemname-install and gemname-compile
logging-compile:
	cd $(gem_src)/logging && rake gem

logging-install:
	cd $(gem_src)/logging && $(Gem_install) pkg/logging*.gem

# Default commands which are not tested :)
%-compile:
	cd $(gem_src)/$* && rake gem

%-install:
	cd $(gem_src)/$* ; $(Gem_install) *.gem

# Install scripts
install: $(foreach script,$(ruby_scripts),$(script_install_dir)/$(script)) ;
$(script_install_dir)/% : $(script_src)/%
	@mkdir -p $(@D)
	cp -p -f $^ $@

clean:
	@echo Cleaning isn\'t implemented at the moment
#             although it may be
