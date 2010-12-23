
# Compilation
all: gem-compile

# Installation
export install_dir=$(prefix)/cluster
bindir?=$(prefix)/bin

nanite_install_dir=$(prefix)/cluster/ruby
ruby_bindir?=$(prefix)/cluster/ruby-bin

targets=actors/node.rb actors/queue.rb init.rb ldvc-mapper ldvc-queue ldvc-wait-task node.rb waiter.rb options.rb sender.rb
bintargets=ldvc-master ldvc-node

cluster_targets=$(targets:%=$(install_dir)/%)
cluster_bintargets=$(bintargets:%=$(bindir)/%)

install: gem-install $(cluster_targets) $(cluster_bintargets)

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
gem-compile:
	cd amqp && ( rm -f amqp.pre.gemspec && rake gem )
	cd nanite && rake gem

export GEM_HOME=$(nanite_install_dir)
Gem_install=gem install --install-dir $(nanite_install_dir) --bindir $(ruby_bindir) --no-rdoc --no-ri

gem-install: gem-compile
	@mkdir -p $(nanite_install_dir)
	$(Gem_install) nanite/pkg/nanite-0.4.1.17.gem
	$(Gem_install) amqp/amqp-0.6.7.gem


define mksubdir
$1-subdir-%:
	$$(MAKE) -C $1 $$*
endef


