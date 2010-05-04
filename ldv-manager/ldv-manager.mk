
Lib_dir:=$(dir $(MAKEFILE_LIST))

# Configuration variables
include config.mk
# Install dir should be absolutized
LDV_INSTALL_DIR:=$(abspath $(LDV_INSTALL_DIR))

# Makefile that performs LDV management
include $(Lib_dir)defs.mk


##################
# Verify input

$(eval $(call assert_notempty,tag))
$(eval $(call assert_notempty,envs))
$(eval $(call assert_notempty,drivers))
$(eval $(call assert_notempty,rule_models))

ifeq ($(name),)
$(warning Variable "name" is empty, falling back to "default")
name=default
endif

#########################
# Split input into tasks

# We start from one default task, and expand it to many others by taking cartesian products with envs, dirvers and models
tasks:=name

delim=^
tasks:=$(call cartprod,$(rule_models),$(tasks),$(delim))
tasks:=$(call cartprod,$(drivers),$(tasks),$(delim))
tasks:=$(call cartprod,$(envs),$(tasks),$(delim))
tasks:=$(call cartprod,$(tag),$(tasks),$(delim))

# Make tasks actual task files
tasks_targets:=$(tasks:%=$(WORK_DIR)/%/finished)

all: $(tasks_targets)

.PHONY: all

#########################
# Split tasks into rules

define rule_for_task
$$(WORK_DIR)/$(1)/finished: Env=$(call get_env_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)/finished: Driver=$(call get_driver_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)/finished: Rule_model=$(call get_rulemodel_raw,$(1),$(delim))

$$(WORK_DIR)/$(1)/finished: $(call get_tag,$(1),$(delim))
	@$$(G_TargetDir)
	@echo ldv --workdir $$(@D) "$(1)"
	@# Add ancillary information to reports and post it to target directory
	@echo $(Lib_dir)report-fixup $$(@D)/report.xml $$^ $$(Driver) $$(Rule_model)
	touch $$@
endef

$(foreach task,$(tasks),$(eval $(call rule_for_task,$(task))))


#########################
# Standard tasks:

# Fetch tag from repository
tags/%/fetched:
	@$(G_TargetDir)
	( flock 200; \
		cd $(@D) && \
		rm -rf ldv-tools && \
		git clone $(LDV_GIT_REPO) ldv-tools && \
		cd ldv-tools && \
		git checkout -q $* && \
		git submodule init && \
		git submodule -q update \
	) 200>$@.lock
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
tags/%/envs: tags/%/installed
	@$(G_TargetDir)
	( flock 200; \
		cd $(LDV_INSTALL_DIR)/$* && \
		export PATH=$(LDV_INSTALL_DIR)/$*/bin:$$PATH ; \
		export LDV_ENVS_TARGET=$(LDV_INSTALL_DIR)/$* ; \
		$(foreach env,$(envs),ldv kmanager add $(abspath $(env)) linux-vanilla $(notdir $(env)) && ) \
		true \
	) 200>$@.lock
	touch $@

tags/%/finished: tags/%/installed tags/%/envs
	touch $@


.PRECIOUS: tags/%/fetched tags/%/finished tags/%/envs



