export SHELL=/bin/bash

ifeq ($(LDV_SRVHOME),)
$(error LDV_SRVHOME is not set!)
endif

Lib_dir:=$(LDV_SRVHOME)/ldv-manager/mk/
Script_dir:=$(LDV_SRVHOME)/ldv-manager/

# Configuration variables
# Include config only if it exists
-include config.mk
# Default configuration
LDV_INSTALL_DIR?=inst
WORK_DIR?=work
RESULTS_DIR?=finished
TMP_DIR?=/tmp

# Special variable that denotes a "fake" tag.  If you specify this "tag", the manager will use currently installed tools available from PATH.
Current=current
ifeq ($(tag),)
$(warning Using whatever LDV tools found in your PATH)
tag=$(Current)
endif

# If verifier is specified, distpatch by it (dash is to separate it from other parts of description string)
# TODO: Add support for more verifiers
ifeq ($(RCV_VERIFIER),)
Verifier=
else
Verifier=$(delim)$(RCV_VERIFIER)
endif


# Install dir should be absolutized
LDV_INSTALL_DIR:=$(abspath $(LDV_INSTALL_DIR))

# Sanity checks
ifeq ($(LDV_GIT_REPO),)
ifneq ($(tag),$(Current))
$(error You should specify git repository in LDV_GIT_REPO)
endif
endif

# Makefile that performs LDV management
include $(Lib_dir)defs.mk


##################
# Verify input

$(eval $(call assert_notempty,tag))
$(eval $(call assert_notempty,envs))
$(eval $(call assert_notempty,drivers))
$(eval $(call assert_notempty,rule_models))

ifneq ($(shell echo '$(drivers)' | grep '\.\.'),)
$(error drivers variable should not contain any .. (double dot) symbols!)
endif

ifeq ($(name),)
name=default
endif

########################
# Process options
ifneq ($(ldv_statuses),)
# This command mitigates error in ldv command, and instead sets the fail status
Fail_status_set= || $(Script_dir)failed-run "$(envs)" "$(drivers)" "$(kernel_driver)" "$(rule_models)"  >$$(@D)/report_after_ldv.xml
endif

#########################
# Split input into tasks

# We start from one default task, and expand it to many others by taking cartesian products with envs, dirvers and models
tasks:=$(name)
calls:=$(name)

delim=--X--
tasks:=$(call cartprod,$(rule_models),$(tasks),$(delim))
tasks:=$(call cartprod,$(envs),$(tasks),$(delim))
tasks:=$(call cartprod,$(drivers),$(tasks),$(delim))
tasks:=$(call cartprod,$(tag),$(tasks),$(delim))

calls:=$(call cartprod,$(drivers),$(calls),$(delim))
calls:=$(call cartprod,$(tag),$(calls),$(delim))

env_names:=$(foreach env,$(envs),$(call envname,$(env)))
# LDV script accepts input in such form: "linux-2.6.31.2@31_2,8_1:linux-2.6.28@31_2,8_1"
ldv_rules:=$(shell echo '$(rule_models)' | sed -e 's/ \+/,/g')
ldv_task:=$(addsuffix @$(ldv_rules),$(env_names))
ldv_task:=$(call joinlist,$(ldv_task),:)

# Descriptor of tasks for use in target names
ldv_task_for_targ:=$(call joinlist,$(env_names),$(delim))$(delim)$(call joinlist,$(rule_models),$(delim))

ifneq ($(kernel_driver),)
Kernel_driver=--kernel-driver
endif

# Make tasks actual task files
# Note that we add $(Verifier) into the targets, since tasks should be distpatched by it as well
tasks_targets:=$(tasks:%=$(WORK_DIR)/%$(ldv_task_for_targ)$(Verifier)/finished)

all: $(tasks_targets)

.PHONY: all

#########################
# Split tasks into rules

# Since Make doesn't support double distpatching (e.g. rules like "dir/%/%/finished: ... "), we generate targets explicitely, from the veriables supplied as input.  These rules are stored in variables rule_for_something and are evaluated in foreach-eval loops.
#
# In the following tasks touch-es are commented in order to make the system restart each time

define rule_for_task
$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: Env=$(call get_env_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: Driver=$(call get_driver_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: Rule_model=$(call get_rulemodel_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: Dir=$(call get_tag_raw,$(1),$(delim))$(delim)$(call get_driver_raw,$(1),$(delim))$(delim)$(call get_name_raw,$(1),$(delim))

$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: $$(WORK_DIR)/$(call get_tag_raw,$(1),$(delim))$(delim)$(call get_driver_raw,$(1),$(delim))$(delim)$(call get_name_raw,$(1),$(delim))$(ldv_task_for_targ)$(Verifier)/finished
endef

# $(@D) has a slash at the end.  We should remove it
rmtr=$(call sed,$(1),s/\/$$//)

define rule_for_tag_driver
$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: Driver=$(call get_driver_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: Tag=$(call get_tag_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: Result_report=
$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: Run_spec=$(if $(cmdstream_driver),--cmdstream=,--driver=)
$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: Ldv_env=$(if $(cmdstream_driver),$(envs)@$(ldv_rules),$(ldv_task))
$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: Tmp_dir=$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/tmp

# We add dependency on the archive with file to allow consecutive launches
# If driver is from cmdstream, we do not prepare kernel
$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/checked: $(if $(cmdstream_driver),,$(call get_tag,$(1),$(delim))) $(if $(kernel_driver),,$(call get_driver_raw,$(1),$(delim)))
	@echo $(1) $$(Driver)
	@$$(G_TargetDir)
	$(if $(subst $(Current),,$(Tag)), export PATH=$(LDV_INSTALL_DIR)/$$(Tag)/bin:$$$$PATH; ) \
	LDV_ENVS_TARGET=$(LDV_INSTALL_DIR)/$$(Tag) \
	ldv task $$(Run_spec)$$(Driver) --workdir=$$(@D) --env=$$(Ldv_env) $(Kernel_driver) $(Fail_status_set)

$$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/finished: $$(WORK_DIR)/$(1)$(ldv_task_for_targ)$(Verifier)/checked
	@# Add ancillary information to reports and post it to target directory
	@echo $(call mkize,$(1))
	@mkdir -p $$(RESULTS_DIR) $$(Tmp_dir)
	$(Script_dir)report-fixup $$(@D)/report_after_ldv.xml $$(Tag) $$(Driver) $(if $(kernel_driver),kernel,external) $$(@D)/report_after_ldv.xml.source/ $$(@D) >$$(Tmp_dir)/$(call mkize,$(1))$(ldv_task_for_targ)$(Verifier).report.xml
	$(Script_dir)package $$(Tmp_dir)/$(call mkize,$(1))$(ldv_task_for_targ)$(Verifier).report.xml $(RESULTS_DIR)/$(call mkize,$(1))$(ldv_task_for_targ)$(Verifier).pax -s '|^$$(Tmp_dir)\/*||'
	$(if $(LDV_REMOVE_ON_SUCCESS),rm -rf $$(@D)/*,)
	@echo "The results of the launch reside in:           $(RESULTS_DIR)/$(call mkize,$(1))$(ldv_task_for_targ)$(Verifier).pax"
endef

$(foreach task,$(tasks),$(eval $(call rule_for_task,$(task))))
$(foreach ccall,$(calls),$(eval $(call rule_for_tag_driver,$(ccall))))



#########################
# Standard tasks:

# For debugging purposes, we may choose to update already installed "tag" instead of fetching a completely new one
# NOTE that you should first remove tags/%/fetched file to trigger downloading then
ifeq ($(update),1)
download_cmd=cd ldv-tools && git fetch && git checkout $(commit)
else
download_cmd=rm -rf ldv-tools && git clone $(LDV_GIT_REPO) ldv-tools && cd ldv-tools && git checkout -q $*
endif

# Fetch tag from repository
tags/%/fetched:
	@$(G_TargetDir)
	( flock 200; \
		cd $(@D) && \
		$(download_cmd) && \
		git submodule update --init --recursive \
	) 200>$@.lock
	touch $@

tags/$(Current)/installed:
	@$(G_TargetDir)
	touch $@

# Install from repo
tags/%/installed: tags/%/fetched
	@$(G_TargetDir)
	( flock 200; \
		cd $(@D)/ldv-tools && \
		prefix=$(LDV_INSTALL_DIR)/$* $(MAKE) install \
	) 200>$@.lock
	touch $@

# Prepare envs for current tag
# TODO: perform double distpatching as in previous example!
# Prepare list of target in form "tag-v2.4/env.linux-2.6.30", that depend on actual files with kernels
envs_tasks:=$(call cartprod,$(tag),$(env_names),/env.)
get_tag_fromenv=$(call sed,$(1),s|/env\..*||)
get_env_fromenv=$(call sed,$(1),s|.*/env\.||)

# Generate task like this:
# tags/tag-v1.2/env.linux-2.6.33: ../../kernels/linux-2.6.33.tar.gz
define rule_for_tag_env
tags/$(1): Env=$(call get_env_fromenv,$(1))
tags/$(1): Env_file=$(2)
tags/$(1): Tag=$(call get_tag_fromenv,$(1))

tags/$(1): $(2) tags/$$(call get_tag_fromenv,$(1))/installed
	( flock 200; \
		$(if $(subst $(Current),,$(Tag)),	cd $(LDV_INSTALL_DIR)/$$(Tag) && export PATH=$(LDV_INSTALL_DIR)/$$(Tag)/bin:$$$$PATH;) \
		export LDV_ENVS_TARGET=$(LDV_INSTALL_DIR)/$$(Tag) ; \
		echo "Preparing kernel $$(Env) from $$(Env_file)..." ;\
		ldv kmanager --action=add --src=$$(abspath $$(Env_file)) --extractor=linux-vanilla --name=$$(Env) $$(silencio) \
	) 200>$@.lock
	touch $$@
endef

$(foreach tag,$(tag),$(foreach env,$(envs),$(eval $(call rule_for_tag_env,$(tag)/env.$(call envname,$(env)),$(env)))))


ifeq ($(verbose_env),)
silencio= >/dev/null
endif
tags/%/envs: $(addprefix tags/%/env.,$(env_names))
	@$(G_TargetDir)
	touch $@

tags/%/finished: tags/%/installed tags/%/envs
	touch $@


.PRECIOUS: tags/%/fetched tags/%/finished tags/%/envs



