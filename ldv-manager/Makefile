
# Compilation
all: 
	@echo LDV-MANAGER doesn\'t require compilation

# Installation
export problem_install_dir=$(prefix)/ldv-problems
bindir?=$(prefix)/bin
ldvm_dir=$(prefix)/ldv-manager
problem_install_dir=$(ldvm_dir)/problems

# Sources and targets
problems=$(shell find problems -type f -executable | sed 's/^problems\/*//')
problem_targets=$(problems:%=$(problem_install_dir)/%)

bin_sources=ldv-problem-recalc ldv-manager ldv-upload ldv-upload-2 path-to-results-schema-sql ldv-load.pl ldv-view-pax
bin_targets=$(bin_sources:%=$(bindir)/%)

mkscript_dir=$(ldvm_dir)/mk
mkscript_sources=$(shell find -iname '*.mk')
mkscript_targets=$(mkscript_sources:%=$(mkscript_dir)/%)

stuff=results_schema.sql results_model.rb report-fixup package failed-run upload_utils.rb
stuff_targets=$(stuff:%=$(ldvm_dir)/%)

install: $(bin_targets) $(problem_targets) $(problem_script_target) $(mkscript_targets) $(stuff_targets)

clean:

$(bindir)/%: %
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@

$(problem_install_dir)/%: problems/%
	@mkdir -p $(@D)
	cp $^ $@
	@chmod +x $@

$(mkscript_dir)/%: %
	@mkdir -p $(@D)
	cp $^ $@

$(ldvm_dir)/%: %
	@mkdir -p $(@D)
	cp $^ $@


