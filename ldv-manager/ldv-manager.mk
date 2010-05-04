
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

ifneq ($(shell echo '$(drivers)' | grep /),)
$(error drivers variable should not contain any / symbols!)
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
tasks_targets:=$(tasks:%=$(WORK_DIR)/%/finished)

all: $(tasks_targets)

.PHONY: all

#########################
# Split tasks into rules

define rule_for_task
$$(WORK_DIR)/$(1)/finished: Env=$(call get_env_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)/finished: Driver=$(call get_driver_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)/finished: Rule_model=$(call get_rulemodel_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)/finished: Dir=$(call get_tag_raw,$(1),$(delim))$(delim)$(call get_driver_raw,$(1),$(delim))$(delim)$(call get_name_raw,$(1),$(delim))

$$(WORK_DIR)/$(1)/finished: $$(WORK_DIR)/$(call get_tag_raw,$(1),$(delim))$(delim)$(call get_driver_raw,$(1),$(delim))$(delim)$(call get_name_raw,$(1),$(delim))/finished
	cd $$(WORK_DIR) && ln -s -T -f $$(Dir) $(1)
endef

env_names:=$(foreach env,$(envs),$(call envname,$(env)))
# Get input to ldv script in form "linux-2.6.31.2x31_2:linux-2.6.31.2x8_1"
ldv_task:=$(call cartprod,$(env_names),$(rule_models),@)
ldv_task:=$(call joinlist,$(ldv_task),:)

ifneq ($(kernel_dirver),)
Kernel_driver=--kernel-driver
endif

define rule_for_tag_driver
$$(WORK_DIR)/$(1)/finished: Driver=$(call get_driver_raw,$(1),$(delim))
$$(WORK_DIR)/$(1)/finished: Tag=$(call get_tag_raw,$(1),$(delim))

$$(WORK_DIR)/$(1)/finished: $(call get_tag,$(1),$(delim))
	@echo $(1) $$(Driver)
	@$$(G_TargetDir)
	export PATH=$(LDV_INSTALL_DIR)/$$(Tag)/bin:$$$$PATH ; \
	LDV_ENVS_TARGET=$(LDV_INSTALL_DIR)/$* \
	ldv task --driver=$$(Driver) --workdir=$$(@D) --env=$(ldv_task) $(Kernel_driver)
	@# Add ancillary information to reports and post it to target directory
	@echo $(Lib_dir)report-fixup $$(@D)/report.xml $$^ $$(Driver) ???
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
		cd $(LDV_INSTALL_DIR)/$$(Tag) && \
		export PATH=$(LDV_INSTALL_DIR)/$$(Tag)/bin:$$$$PATH ; \
		export LDV_ENVS_TARGET=$(LDV_INSTALL_DIR)/$$(Tag) ; \
		ldv kmanager add $$(abspath $$(Env_file)) linux-vanilla $$(Env) $(silencio) \
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



