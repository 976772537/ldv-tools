srcdir = .
VPATH =  ${srcdir}

SHELL= /bin/sh

BUILD_SUBDIRS = rule-instrumentor error-trace-visualizer cmd-utils build-cmd-extractor drv-env-gen dscv kernel-rules ldv ldv-core shared/perl shared/php shared/sh ldv-manager ldv-online ldv-git watcher
LDV_MANAGER_SUBDIRS = ldv-manager $(DSCV_SUBDIRS) ldv drv-env-gen cmd-utils build-cmd-extractor ldv ldv-core shared/sh error-trace-visualizer
ERROR_TRACE_VISUALIZER_SUBDIRS = error-trace-visualizer shared/perl
DSCV_SUBDIRS = rule-instrumentor dscv kernel-rules shared/perl
LDV_SUBDIRS = $(DSCV_SUBDIRS) $(LDV_MANAGER_SUBDIRS) $(ERROR_TRACE_VISUALIZER_SUBDIRS) drv-env-gen cmd-utils build-cmd-extractor ldv ldv-core shared/perl shared/sh watcher
STATS_SUBDIRS = $(ERROR_TRACE_VISUALIZER_SUBDIRS) stats-visualizer shared/php
ONLINE_SUBDIRS = ldv-online 
TESTS_SUBDIRS = ldv-tests $(LDV_MANAGER_SUBDIRS)
LDV_GIT_SUBDIRS = $(LDV_SUBDIRS) ldv-git


SUBDIRS = $(BUILD_SUBDIRS)
INSTALL_SUBDIRS = $(LDV_SUBDIRS)
CLEAN_SUBDIRS = $(SUBDIRS)

# Export prefix to sub-make invocations for subdirectories
export prefix

# Dependencies names generator. 
forall_subdirs=$(patsubst %,%-subdir-$2,$1)
# Generic rule for descending into subdirectories.  Used for eval-ing
define mksubdir
$1-subdir-%:
	$$(MAKE) -C $1 $$*

endef

all: $(call forall_subdirs,$(SUBDIRS),all)

install: install-console-tools

install-all: $(call forall_subdirs,$(SUBDIRS),install)

install-console-tools: pre_tests ocaml_is_installed ant_is_installed java_is_installed pax_is_installed $(call forall_subdirs,$(LDV_SUBDIRS),install)

install-verifiers: pre_tests ocaml_is_installed $(call forall_subdirs,$(DSCV_SUBDIRS),install)

# Install only statistics server
install-visualization: pre_tests $(call forall_subdirs,$(STATS_SUBDIRS),install)

# Install only test stuff
install-testing: pre_tests $(call forall_subdirs,$(TESTS_SUBDIRS),install)

# Install only test stuff
install-ldv-git: pre_tests $(call forall_subdirs,$(LDV_GIT_SUBDIRS),install)

clean: $(call forall_subdirs,$(CLEAN_SUBDIRS),clean)

distclean: clean

# Let's instantiate rules for subdirs:
$(foreach subdir,$(SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(ERROR_TRACE_VISUALIZER_SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(DSCV_SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(LDV_SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(STATS_SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(ONLINE_NODE_SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(ONLINE_SERVER_SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(LDV_MANAGER_SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(TESTS_SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(LDV_GIT_SUBDIRS),$(eval $(call mksubdir,$(subdir))))

pre_tests:
	@$(call test_var_prefix)

configure:
	echo "configure - Ok";



pax_is_installed:
	@$(call is_installed,pax)

perl_is_installed:
	@$(call is_installed,perl)

ruby_is_installed:
	@$(call is_installed,ruby)

ocaml_is_installed:
	@$(call is_installed,ocaml)

ant_is_installed:
	@$(call is_installed,ant)

java_is_installed:
	@$(call is_installed,java)

define test_var_prefix
	if [ -n "$(prefix)" ]; then                                  \
		true;                                                \
	else                                                         \
		echo " "; 					     \
		echo "******************** error *****************"; \
		echo "* usage: prefix=/install/dir make ...      *"; \
		echo "********************************************"; \
		echo " "; 					     \
		false;                                               \
        fi
endef

define is_installed
	echo " Test: $1 is installed..."; 			     \
	if which $1; then 		                             \
		echo " Ok - $1 installed.";                          \
		true;                                                \
	else                                                         \
		echo " "; 					     \
		echo "******************** ERROR *****************"; \
		echo "* Can't find $1 in your path.              *"; \
		echo "* It's really installed?                   *"; \
		echo "********************************************"; \
		echo " "; 					     \
		false;                                               \
        fi
endef










