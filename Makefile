srcdir = .
VPATH =  ${srcdir}

SHELL= /bin/sh

BUILD_SUBDIRS = ri etv cmd-utils build-cmd-extractor drv-env-gen dscv kernel-rules ldv ldv-core shared/perl shared/php shared/sh ldv-manager ldv-online ldv-git watcher cluster shared/ruby res-manager
LDV_MANAGER_SUBDIRS = ldv-manager $(DSCV_SUBDIRS) ldv drv-env-gen cmd-utils build-cmd-extractor ldv ldv-core shared/sh etv res-manager
ETV_SUBDIRS = etv shared/perl
KB_SUBDIRS = knowledge-base shared/perl
RI_SUBDIRS = ri kernel-rules shared/perl
DSCV_SUBDIRS = ri dscv kernel-rules shared/perl
LDV_SUBDIRS = $(DSCV_SUBDIRS) $(LDV_MANAGER_SUBDIRS) $(ETV_SUBDIRS) $(KB_SUBDIRS) drv-env-gen cmd-utils build-cmd-extractor ldv ldv-core shared/perl shared/sh watcher shared/ruby res-manager
STATS_SUBDIRS = $(ETV_SUBDIRS) $(KB_SUBDIRS) stats-visualizer kernel-rules shared/php
ONLINE_SUBDIRS = ldv-online 
CLUSTER_SUBDIRS = cluster shared/ruby
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

install: install-console-tools install-ldv-git

install-all: $(call forall_subdirs,$(SUBDIRS),install)

install-console-tools: pre_tests ocaml_is_installed ant_is_installed java_is_installed pax_is_installed $(call forall_subdirs,$(LDV_SUBDIRS),install)

install-verifiers: pre_tests ocaml_is_installed $(call forall_subdirs,$(DSCV_SUBDIRS),install)

# Install only Rule Instrumentor, C Instrumentation Framework, Aspectator and kernel rules
install-ri: pre_tests $(call forall_subdirs,$(RI_SUBDIRS),install)

# Install only error trace visualizer
install-etv: pre_tests $(call forall_subdirs,$(ETV_SUBDIRS),install)

# Install only statistics server
install-visualization: pre_tests $(call forall_subdirs,$(STATS_SUBDIRS),install)

# Install only test stuff
install-testing: pre_tests $(call forall_subdirs,$(TESTS_SUBDIRS),install)

# Install only test stuff
install-ldv-git: pre_tests $(call forall_subdirs,$(LDV_GIT_SUBDIRS),install)

# Install cluster
install-cluster: pre_tests ocaml_is_installed $(call forall_subdirs,$(CLUSTER_SUBDIRS),install)

clean: $(call forall_subdirs,$(CLEAN_SUBDIRS),clean)

distclean: clean

# Let's instantiate rules for subdirs:
$(foreach subdir,$(SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(ETV_SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(KB_SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(RI_SUBDIRS),$(eval $(call mksubdir,$(subdir))))
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
	case "$(prefix)" in \
		/*) prefix_abs=1 ;; \
		*) prefix_abs=0 ;; \
	esac; \
	if [ -n "$(prefix)" -a $$prefix_abs -eq 1 ]; then                                  \
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










