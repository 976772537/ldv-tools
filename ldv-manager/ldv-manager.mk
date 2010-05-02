# Makefile that performs LDV management

include defs.mk

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
$$(WORK_DIR)/$(1)/finished: $(call get_tag,$(1),$(delim)) $(call get_env,$(1),$(delim))
	@$$(G_TargetDir)
	@echo ldv "$(1)"
	touch $$@
endef

$(foreach task,$(tasks),$(eval $(call rule_for_task,$(task))))


#########################
# Standard tasks:

tags/%/finished:
	@$(G_TargetDir)
	echo tag $*
	touch $@

envs/%/finished:
	@$(G_TargetDir)
	echo env $*
	touch $@




