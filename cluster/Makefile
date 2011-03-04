
# Compilation
all: gem-compile

# Installation
export install_dir=$(prefix)/cluster
bindir?=$(prefix)/bin

nanite_install_dir=$(prefix)/cluster/ruby
ruby_bindir?=$(prefix)/cluster/ruby-bin

targets=actors/node.rb actors/queue.rb init.rb ldvc-mapper ldvc-queue ldvc-wait-task node.rb waiter.rb options.rb sender.rb ldvc-node-impl queue.rb utils.rb cluster-watcher.rb utils/logging.rb packer.rb utils/open3.rb
bintargets=ldvc-master ldvc-node

cluster_targets=$(targets:%=$(install_dir)/%)
cluster_bintargets=$(bintargets:%=$(bindir)/%)

install: $(cluster_targets) $(cluster_bintargets)

ifndef NO_GEMS
install: gem-install
endif

install-tests:
	@mkdir -p $(install_dir)/rspec
	cp rspec/*.rb $(install_dir)/rspec

clean:
	cd nanite && rake clean

$(install_dir)/%: %
	@mkdir -p $(@D)
	cp -f -p $^ $@

$(bindir)/%: %
	@mkdir -p $(@D)
	cp -f -p $^ $@
	@chmod +x $@

# Nanite
gem-compile: amqp-compile nanite-compile

amqp-compile:
	cd amqp && gem build amqp.gemspec

nanite-compile: amqp-install
	cd nanite && rake gem

export GEM_HOME=$(nanite_install_dir)
ifndef GEM_DOC
no_rdoc=--no-rdoc
endif
Gem_install=gem install --install-dir $(nanite_install_dir) --bindir $(ruby_bindir) $(no_rdoc) --no-ri

gem-install: nanite-install amqp-install
	@mkdir -p $(nanite_install_dir)

nanite-install: nanite-compile
	$(Gem_install) nanite/pkg/nanite-0.4.1.17.gem

amqp-install: amqp-compile
	$(Gem_install) amqp/amqp-0.6.7.gem


define mksubdir
$1-subdir-%:
	$$(MAKE) -C $1 $$*
endef


