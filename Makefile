srcdir = .
VPATH =  ${srcdir}

SHELL= /bin/sh

BUILD_SUBDIRS = rule-instrumentor kernel-rules cmd-utils build-cmd-extractor drv-env-gen dscv kernel-rules ldv ldv-core
DEBUG_MAKEFILE_SUBDIRS = build-cmd-extractor cmd-utils  drv-env-gen kernel-rules ldv  ldv-core

SUBDIRS = $(BUILD_SUBDIRS)
INSTALL_SUBDIRS = $(SUBDIRS)
CLEAN_SUBDIRS = $(SUBDIRS)

target: pre_tests
	for dir in ${SUBDIRS} ; do ( cd $$dir ; export prefix=${prefix}; ${MAKE}; ) ; done
	for dir in ${SUBDIRS} ; do ( cd $$dir ; export prefix=${prefix}; ${MAKE} install; ) ; done

all: pre_tests
	for dir in ${SUBDIRS} ; do ( cd $$dir ; export prefix=${prefix}; ${MAKE} all ) ; done

install: pre_tests
	for dir in ${INSTALL_SUBDIRS} ; do ( cd $$dir ; export prefix=${prefix}; ${MAKE} install ) ; done

clean: pre_tests
	for dir in ${CLEAN_SUBDIRS} ; do ( cd $$dir ; ${MAKE} clean ) ; done


distclean: clean

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









