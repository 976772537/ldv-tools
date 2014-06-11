INSTALL_DIR = __install

# File that contains statistics server variables defined by user.
CONFIG = config

ifneq ($(wildcard $(CONFIG)),)
  include $(CONFIG)
endif

VHOST_DIR = vhosts
STATS_DIR = ldv-stats
STATS_ROOT = public
PROFILES_DIR = profiles

WEB_SERVER = apache2
WEB_SERVER_VHOSTS_CONF_DIR = vhosts.d
WEB_SERVER_VHOSTS_CONF = ldv-stats.conf
WEB_SERVER_VHOSTS_CONF_VHOSTS_DIR = LDV_STATS_VHOSTS_DIR
WEB_SERVER_VHOSTS_CONF_STATS_ROOT = LDV_STATS_ROOT
WEB_SERVER_VHOSTS_CONF_APPLICATION_ENV = LDV_STATS_APPLICATION_ENV
WEB_SERVER_CONF_DIR = conf.d
WEB_SERVER_CONF = ldv-stats.conf
WEB_SERVER_CONF_PORT = LDV_STATS_PORT

# Default values of statistics server port, application environment and profile database overwriting options.
DEFAULT_PORT = 8999
DEFAULT_APPLICATION_ENV = production
DEFAULT_OVERWRITE_PROFILE_DB = no

# The default profiles database. It's relative to the profiles directory.
DEFAULT_PROFILE_DB = profile.db

# Zend framework shared directory. It's relative to the prefix directory.
ZEND_FRAMEWORK_DIR = shared/php/Zend
# Zend framework library directory. It's relative to the statistics server virtual directory.
ZEND_FRAMEWORK_LIBRARY_DIR = $(STATS_DIR)/library
# Zend framework link. It's relative to the statistics server library directory.
ZEND_FRAMEWORK_LINK = Zend

# Some data files. They are relative to the statistics server directory.
STATS_DATA = data
STATS_DB = db
STATS_PROFILE_DB = profile.db
STATS_TRACE = trace
STATS_TRACE_ORIGINAL = original
STATS_TRACE_PROCESSED = processed
STATS_SRC = src
STATS_KB_DUMP = kb-dump.sql

# The application directory. It's relative to the statistics server directory.
STATS_APPLICATION = application

# Some configuration files. They are relative to the application directory.
STATS_CONFIG = configs
STATS_CONFIG_DATA = data.ini
STATS_CONFIG_ERROR_TRACE_VISUALIZER = [error-trace-visualizer]
STATS_CONFIG_KB_RECALC = [kb-recalc]
STATS_CONFIG_PPOB_PUBLISHER = [ppob-publisher]
STATS_CONFIG_SCRIPT = script=
STATS_CONFIG_MODEL_DB = [model-database]
STATS_CONFIG_RULE_DB = [rule-database]
STATS_CONFIG_FILE = file=

# Error trace visualizer script. It's relative to the bin directory.
ERROR_TRACE_VISUALIZER = etv

# Knowledge base cache (re)generation script. It's relative to the bin directory.
KB_RECALC = kb-recalc.pl

# Public Pool of Bugs publisher script. It's relative to the bin directory.
PPOB_PUBLISHER = ppob-publisher.pl

# Model database xml file. It's relative to the prefix directory.
STATS_CONFIG_MODEL_DB_FILE = kernel-rules/model-db.xml

# Rule database xml file. It's relative to the prefix directory.
STATS_CONFIG_RULE_DB_FILE = kernel-rules/rules/DRVRULES_en.trl

# Standard Makefile section.
# Use root installation directory if no prefix was specified.
ifndef prefix
prefix = `readlink -f $(INSTALL_DIR)`
endif
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
mandir = ${prefix}/man

# Phony targets.
.PHONY: all install test clean

# Default make action.
all:
	@echo The statistics server doesn\'t require compilation

# Install needed files to specified paths.
install:
	@if [ ! -n "$(LDV_STATS_CONF_DIR)" ]; then echo 'Specify the LDV_STATS_CONF_DIR variable value!' && exit 1; else echo 'LDV_STATS_CONF_DIR is $(LDV_STATS_CONF_DIR)'; fi
	@if [ ! -n "$(LDV_STATS_VHOSTS_CONF_DIR)" ]; then echo 'Specify the LDV_STATS_VHOSTS_CONF_DIR variable value!' && exit 1; else echo 'LDV_STATS_VHOSTS_CONF_DIR is $(LDV_STATS_VHOSTS_CONF_DIR)'; fi
	@if [ ! -n "$(LDV_STATS_VHOSTS_DIR)" ]; then echo 'Specify the LDV_STATS_VHOSTS_DIR variable value!' && exit 1; else echo 'LDV_STATS_VHOSTS_DIR is $(LDV_STATS_VHOSTS_DIR)'; fi
	@if [ ! -d $(LDV_STATS_CONF_DIR) ]; then echo 'The specified web server configuration directory "$(LDV_STATS_CONF_DIR)" does not exist' && exit 1; fi;
	@if [ ! -d $(LDV_STATS_VHOSTS_CONF_DIR) ]; then echo 'The specified web server virtual hosts configuration directory "$(LDV_STATS_VHOSTS_CONF_DIR)" does not exist' && exit 1; fi;
	@if [ ! -d $(LDV_STATS_VHOSTS_DIR) ]; then echo 'The specified web server virtual hosts directory "$(LDV_STATS_VHOSTS_DIR)" does not exist' && exit 1; fi;

	@if [ ! -n "$(LDV_STATS_PORT)" ]; then echo 'The default LDV_STATS_PORT "$(DEFAULT_PORT)" is used' && export LDV_STATS_PORT=$(DEFAULT_PORT); else echo 'LDV_STATS_PORT is $(LDV_STATS_PORT)'; export LDV_STATS_PORT=$(LDV_STATS_PORT); fi; \
	if [ ! -n "$(LDV_STATS_APPLICATION_ENV)" ]; then echo 'The default LDV_STATS_APPLICATION_ENV "$(DEFAULT_APPLICATION_ENV)" is used' && export LDV_STATS_APPLICATION_ENV=$(DEFAULT_APPLICATION_ENV); else echo 'LDV_STATS_APPLICATION_ENV is $(LDV_STATS_APPLICATION_ENV)'; export LDV_STATS_APPLICATION_ENV=$(LDV_STATS_APPLICATION_ENV); fi; \
	\
	export WEB_SERVER_CONF_ABS=`readlink -f $(LDV_STATS_CONF_DIR)/$(WEB_SERVER_CONF)`; \
	export WEB_SERVER_VHOSTS_CONF_ABS=`readlink -f $(LDV_STATS_VHOSTS_CONF_DIR)/$(WEB_SERVER_VHOSTS_CONF)`; \
	cat $(WEB_SERVER)/$(WEB_SERVER_CONF_DIR)/$(WEB_SERVER_CONF) | sed -e "s/$(WEB_SERVER_CONF_PORT)/$$LDV_STATS_PORT/g" > $$WEB_SERVER_CONF_ABS; \
	cat $(WEB_SERVER)/$(WEB_SERVER_VHOSTS_CONF_DIR)/$(WEB_SERVER_VHOSTS_CONF) | \
	  sed -e "s/$(WEB_SERVER_CONF_PORT)/$$LDV_STATS_PORT/g" \
	    -e 's|$(WEB_SERVER_VHOSTS_CONF_VHOSTS_DIR)|$(LDV_STATS_VHOSTS_DIR)|g' \
	    -e 's|$(WEB_SERVER_VHOSTS_CONF_STATS_ROOT)|$(STATS_DIR)/$(STATS_ROOT)|g' \
	    -e "s|$(WEB_SERVER_VHOSTS_CONF_APPLICATION_ENV)|$$LDV_STATS_APPLICATION_ENV|g" \
	  | if [ $$WEB_SERVER_CONF_ABS == $$WEB_SERVER_VHOSTS_CONF_ABS ]; then echo '' >> $$WEB_SERVER_VHOSTS_CONF_ABS && cat >> $$WEB_SERVER_VHOSTS_CONF_ABS && echo 'Concatenate virtual host configuration to general configuration'; else cat > $$WEB_SERVER_VHOSTS_CONF_ABS && echo 'Write virtual host configuration and general configuration to different files'; fi;

	cp -r $(VHOST_DIR)/$(STATS_DIR) $(LDV_STATS_VHOSTS_DIR) || exit 1;
	@if [ ! -d $(LDV_STATS_VHOSTS_DIR)/$(ZEND_FRAMEWORK_LIBRARY_DIR) ]; then mkdir -p $(LDV_STATS_VHOSTS_DIR)/$(ZEND_FRAMEWORK_LIBRARY_DIR) || exit 1; fi
	ln -sfT "$(prefix)/$(ZEND_FRAMEWORK_DIR)" "$(LDV_STATS_VHOSTS_DIR)/$(ZEND_FRAMEWORK_LIBRARY_DIR)/$(ZEND_FRAMEWORK_LINK)" || exit 1;
	@echo Create the needed files
	@if [ ! -d $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_DB) ]; then mkdir -p $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_DB) || exit 1; fi
	@if [ ! -n "$(LDV_STATS_OVERWRITE_PROFILE_DB)" ]; then echo 'The default LDV_STATS_OVERWRITE_PROFILE_DB "$(DEFAULT_OVERWRITE_PROFILE_DB)" is used' && export LDV_STATS_OVERWRITE_PROFILE_DB=$(DEFAULT_OVERWRITE_PROFILE_DB); else echo 'LDV_STATS_OVERWRITE_PROFILE_DB is $(LDV_STATS_OVERWRITE_PROFILE_DB)'; export LDV_STATS_OVERWRITE_PROFILE_DB=$(LDV_STATS_OVERWRITE_PROFILE_DB); fi; \
	if [ ! -f "$(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_DB)/$(STATS_PROFILE_DB)" -o $$LDV_STATS_OVERWRITE_PROFILE_DB = "yes" ]; then cp $(PROFILES_DIR)/$(DEFAULT_PROFILE_DB) $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_DB)/$(STATS_PROFILE_DB) || exit 1; echo 'The profiles database was updated'; else echo 'The previosly created profiles database $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_DB)/$(STATS_PROFILE_DB) will be used'; fi;
	@if [ ! -d $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_TRACE) ]; then mkdir -p $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_TRACE) || exit 1; fi
	touch $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_TRACE)/$(STATS_TRACE_ORIGINAL) || exit 1;
	touch $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_TRACE)/$(STATS_TRACE_PROCESSED) || exit 1;
	touch $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_TRACE)/$(STATS_SRC) || exit 1
	touch $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_KB_DUMP) || exit 1
	@if [ ! -d $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_APPLICATION)/$(STATS_CONFIG) ]; then mkdir -p $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_APPLICATION)/$(STATS_CONFIG) || exit 1; fi
	touch $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_APPLICATION)/$(STATS_CONFIG)/$(STATS_CONFIG_DATA) || exit 1;
	@echo Give the correct access to the needed files to the statistics server
	@if [ ! -n "$(LDV_STATS_USER)" -o ! -n "$(LDV_STATS_GROUP)" ]; then echo 'Specify the LDV_STATS_USER and LDV_STATS_GROUP variable values if you want to grant the correct access to the statistics server!'; \
	  else echo 'LDV_STATS_USER is $(LDV_STATS_USER)'; echo 'LDV_STATS_GROUP is $(LDV_STATS_GROUP)'; \
	    chown $(LDV_STATS_USER):$(LDV_STATS_GROUP) $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_DB)/$(STATS_PROFILE_DB) $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_TRACE)/$(STATS_TRACE_ORIGINAL) $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_TRACE)/$(STATS_TRACE_PROCESSED) $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_TRACE)/$(STATS_SRC) $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_DATA)/$(STATS_KB_DUMP) || exit 1; \
	fi
	@echo Add pathes to scripts and model/rule databases to the statistics server script configuration file
	export ETV="$(STATS_CONFIG_ERROR_TRACE_VISUALIZER)\n$(STATS_CONFIG_SCRIPT)$(bindir)/$(ERROR_TRACE_VISUALIZER)"; \
	export KBR="$(STATS_CONFIG_KB_RECALC)\n$(STATS_CONFIG_SCRIPT)$(bindir)/$(KB_RECALC)"; \
	export PPOBP="$(STATS_CONFIG_PPOB_PUBLISHER)\n$(STATS_CONFIG_SCRIPT)$(bindir)/$(PPOB_PUBLISHER)"; \
	export MODEL_DB="$(STATS_CONFIG_MODEL_DB)\n$(STATS_CONFIG_FILE)$(prefix)/$(STATS_CONFIG_MODEL_DB_FILE)"; \
	export RULE_DB="$(STATS_CONFIG_RULE_DB)\n$(STATS_CONFIG_FILE)$(prefix)/$(STATS_CONFIG_RULE_DB_FILE)"; \
	printf "$$ETV\n$$KBR\n$$PPOBP\n$$MODEL_DB\n$$RULE_DB\n" > $(LDV_STATS_VHOSTS_DIR)/$(STATS_DIR)/$(STATS_APPLICATION)/$(STATS_CONFIG)/$(STATS_CONFIG_DATA)

test:
	@echo The statistics server doesn\'t have any test

clean:
	@echo The statistics server doesn\'t require cleaning
