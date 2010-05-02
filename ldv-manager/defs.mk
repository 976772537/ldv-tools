# Various helpful definitions

WORK_DIR?=work
RESULTS_DIR?=finished

# Replace all non-alphanumeric chars with -
mkize=$(shell echo '$(1)' | sed -e 's/[^[:alnum:]]\+/-/g')

# Get name of the task.  Arguments:
#	- tag
#	- driver
#	- rule-model
#	- environment (kernel)
#	- human-readable name
task_name?=$(call mkize,$(1))-$(call mkize,$(2))-$(call mkize,$(3))-$(call mkize,$(4))-$(call mkize,$(5))

get_tag_raw=$(shell echo '$(1)'       | cut -f 1 -d $(2))
get_env_raw=$(shell echo '$(1)'       | cut -f 2 -d $(2))
get_driver_raw=$(shell echo '$(1)'    | cut -f 3 -d $(2))
get_rulemodel_raw=$(shell echo '$(1)' | cut -f 4 -d $(2))

get_tag=tags/$(call get_tag_raw,$(1),$(2))/finished
get_driver=drivers/$(call get_driver_raw,$(1),$(2))/finished
get_rulemodel=rulemodels/$(call get_rulemodel_raw,$(1),$(2))/finished
get_env=envs/$(call get_env_raw,$(1),$(2))/finished

# Assertion: if variable with name in $(1) is empty.
define assert_notempty
ifeq ($$($(1)),)
	$$(error Variable "$(1)" should not be empty!)
endif
endef

# Cartesian product
# Input: two lists and separator
cartprod=$(foreach first_iter,$(1),$(addprefix $(first_iter)$(3),$(2)))

# Define task's working directory
task_work_dir?=$(task_file:$(PROCESSING_DIR)/%=$(WORK_DIR)/%)
#Directory for generated files
gen_dir=$(task_work_dir)/gen
# Directory for triggers
triggers_dir?=$(task_work_dir)/triggers

# Guard for target directory creation
G_TargetDir=@mkdir -p "$(@D)"



