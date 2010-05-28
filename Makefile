srcdir = .
VPATH =  ${srcdir}

SHELL= /bin/sh

BUILD_SUBDIRS = rule-instrumentor error-trace-visualizer kernel-rules cmd-utils build-cmd-extractor drv-env-gen dscv kernel-rules ldv ldv-core shared/perl shared/sh
SERVER_SUBDIRS = ldv-manager
DEBUG_MAKEFILE_SUBDIRS = build-cmd-extractor cmd-utils  drv-env-gen kernel-rules ldv  ldv-core

SUBDIRS = $(BUILD_SUBDIRS)
INSTALL_SUBDIRS = $(SUBDIRS)
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

all-all: $(call forall_subdirs,$(SUBDIRS) $(SERVER_SUBDIRS),all)

install: pre_tests $(call forall_subdirs,$(INSTALL_SUBDIRS),install)

install-all: pre_tests $(call forall_subdirs,$(INSTALL_SUBDIRS) $(SERVER_SUBDIRS),install)

# Install only server stuff
install-srv: $(call forall_subdirs,shared/perl shared/sh $(SERVER_SUBDIRS),install)

clean: $(call forall_subdirs,$(CLEAN_SUBDIRS),clean)

clean-all: $(call forall_subdirs,$(CLEAN_SUBDIRS) $(SERVER_SUBDIRS),clean)

distclean: clean

# Let's instantiate rules for subdirs:
$(foreach subdir,$(SUBDIRS),$(eval $(call mksubdir,$(subdir))))
$(foreach subdir,$(SERVER_SUBDIRS),$(eval $(call mksubdir,$(subdir))))


pre_tests:
	@$(call test_var_prefix)

configure:
	echo "configure - Ok";

define test_var_prefix
	if [ -n "$(prefix)" ]; then                                  \
		true;                                                \
	else                                                         \
		echo " "; 					     \
		echo "******************** ERROR *****************"; \
		echo "* USAGE: prefix=/install/dir make          *"; \
		echo "********************************************"; \
		echo " "; 					     \
		false;                                               \
        fi
endef









