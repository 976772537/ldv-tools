export SHELL=/bin/bash

Lib_dir:=$(dir $(MAKEFILE_LIST))

# Configuration variables
# Include config only if it exists
ifneq ($(shell test -f config.mk && echo something),)
include config.mk
endif
# Default configuration
LDV_INSTALL_DIR?=inst
WORK_DIR?=work
RESULTS_DIR?=finished
TMP_DIR?=/tmp

# Special variable that denotes a "fake" tag.  If you specify this "tag", the manager will use currently installed tools available from PATH.
Current=current

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
$(error You should specify git repository in LDV_GIT_REPO)
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
$(warning Variable "name" is empty, falling back to "default")
name=default
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

# Make tasks actual task files
# Note that we add $(Verifier) into the targets, since tasks should be distpatched by it as well
tasks_targets:=$(tasks:%=$(WORK_DIR)/%$(Verifier)/finished)

all: $(tasks_targets)

.PHONY: all

#########################
# Split tasks into rules

# Since Make doesn't support double distpatching (e.g. rules like "dir/%/%/finished: ... "), we generate targets explicitely, from the veriables supplied as input.  These rules are stored in variables rule_for_something and are evaluated in foreach-eval loops.

define rule_for_task
$$(WORK_DIR)/$(1)$(Verifier)/finished: Env=$(call get_env_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)$(Verifier)/finished: Driver=$(call get_driver_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)$(Verifier)/finished: Rule_model=$(call get_rulemodel_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)$(Verifier)/finished: Dir=$(call get_tag_raw,$(1),$(delim))$(delim)$(call get_driver_raw,$(1),$(delim))$(delim)$(call get_name_raw,$(1),$(delim))

$$(WORK_DIR)/$(1)$(Verifier)/finished: $$(WORK_DIR)/$(call get_tag_raw,$(1),$(delim))$(delim)$(call get_driver_raw,$(1),$(delim))$(delim)$(call get_name_raw,$(1),$(delim))$(Verifier)/finished
	cd $$(WORK_DIR) && ln -s -T -f $$(Dir) $(1)
endef

env_names:=$(foreach env,$(envs),$(call envname,$(env)))
# LDV script accepts input in such form: "linux-2.6.31.2@31_2,8_1:linux-2.6.28@31_2,8_1"
ldv_rules:=$(shell echo '$(rule_models)' | sed -e 's/ \+/,/g')
ldv_task:=$(addsuffix @$(ldv_rules),$(env_names))
ldv_task:=$(call joinlist,$(ldv_task),:)

ifneq ($(kernel_driver),)
Kernel_driver=--kernel-driver
endif

# $(@D) has a slash at the end.  We should remove it
rmtr=$(call sed,$(1),s/\/$$//)

define rule_for_tag_driver
$$(WORK_DIR)/$(1)$(Verifier)/finished: Driver=$(call get_driver_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)$(Verifier)/finished: Tag=$(call get_tag_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)$(Verifier)/finished: Result_report=

# We add dependency on the archive with file to allow consecutive launches
$$(WORK_DIR)/$(1)$(Verifier)/checked: $(call get_tag,$(1),$(delim)) $(if $(kernel_driver),,$(call get_driver_raw,$(1),$(delim)))
	@echo $(1) $$(Driver)
	@$$(G_TargetDir)
	if [[ "$$(Tag)" != "$(Current)" ]] ; then \
		export PATH=$(LDV_INSTALL_DIR)/$$(Tag)/bin:$$$$PATH ; \
	fi ;\
	LDV_ENVS_TARGET=$(LDV_INSTALL_DIR)/$$(Tag) \
	ldv task --driver=$$(Driver) --workdir=$$(@D) --env=$(ldv_task) $(Kernel_driver)
	touch $$@

$$(WORK_DIR)/$(1)$(Verifier)/finished: $$(WORK_DIR)/$(1)$(Verifier)/checked
	@# Add ancillary information to reports and post it to target directory
	@echo $(call mkize,$(1))
	@mkdir -p $$(dir $(RESULTS_DIR)/$$(call rmtr,$$(@D)).report.xml)
	$(Lib_dir)report-fixup $$(@D)/report_after_ldv.xml $$(Tag) $$(Driver) $(if $(kernel_driver),kernel,external) $$(@D)/report_after_ldv.xml.source/ $$(@D) >$(TMP_DIR)/$(call mkize,$(1))$(Verifier).report.xml
	$(Lib_dir)package $(TMP_DIR)/$(call mkize,$(1))$(Verifier).report.xml $(RESULTS_DIR)/$(call mkize,$(1))$(Verifier).pax -s '|^$(TMP_DIR)\/*||'
	touch $$@
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
		git submodule init && \
		git submodule -q update \
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
envs_tasks:=$(call cartprod,$(tags),$(env_names),/env.)
get_tag_fromenv=$(call sed,$(1),s|/.*||)
get_env_fromenv=$(call sed,$(1),s|.*/env\.||)

# Generate task like this:
# tags/tag-v1.2/env.linux-2.6.33: ../../kernels/linux-2.6.33.tar.gz
define rule_for_tag_env
tags/$(1): Env=$(call get_env_fromenv,$(1))
tags/$(1): Env_file=$(2)
tags/$(1): Tag=$(call get_tag_fromenv,$(1))

tags/$(1): $(2) tags/$$(call get_tag_fromenv,$(1))/installed 
	( flock 200; \
		if [[ "$$(Tag)" != "$(Current)" ]] ; then \
			cd $(LDV_INSTALL_DIR)/$$(Tag) && \
			export PATH=$(LDV_INSTALL_DIR)/$$(Tag)/bin:$$$$PATH ; \
		fi ; \
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



