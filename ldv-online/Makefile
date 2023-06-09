# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

LDV_ONLINE_DIRNAME=ldv-online
LDV_ONLINE_WWW_DIRNAME=ldvwface
LDV_ONLINE_SCRIPTS_DIRNAME=scripts
LDV_ONLINE_SERVER_DIRNAME=ldvsrv
LDV_ONLINE_SERVER_BIN_DIRNAME=bin
LDV_ONLINE_SERVER_BIN_DIR=$(LDV_ONLINE_SERVER_DIRNAME)/$(LDV_ONLINE_SERVER_BIN_DIRNAME)
LDV_ONLINE_LIBS_DIRNAME=lib
LDV_ONLINE_DIST_DIRNAME=dist
LDV_ONLINE_CONF_DIRNAME=conf
LDV_ONLINE_LIBS_DIR=$(LDV_ONLINE_SERVER_DIRNAME)/$(LDV_ONLINE_LIBS_DIRNAME)
LDV_ONLINE_DIST_DIR=$(LDV_ONLINE_SERVER_DIRNAME)/$(LDV_ONLINE_DIST_DIRNAME)
LDV_ONLINE_INSTALL_SERVER_SCRIPT_FILENAME=install-server.sh
LDV_ONLINE_INSTALL_CLIENT_SCRIPT_FILENAME=install-client.sh
LDV_ONLINE_INSTALL_MIGRATE_SCRIPT_FILENAME=migrate.sh
LDV_ONLINE_INSTALL_DBBACKUP_SCRIPT_FILENAME=db_backup.sh
LDV_ONLINE_CLIENT_SCRIPT_FILENAME=ldv_client
LDV_ONLINE_SERVER_SCRIPT_FILENAME=ldv_server
LDV_ONLINE_SERVER_SCRIPT=$(LDV_ONLINE_SERVER_BIN_DIR)/$(LDV_ONLINE_SERVER_SCRIPT_FILENAME)
LDV_ONLINE_CLIENT_SCRIPT=$(LDV_ONLINE_SERVER_BIN_DIR)/$(LDV_ONLINE_CLIENT_SCRIPT_FILENAME)

LDV_INSTALLED_ONLINE_DIR=$(prefix)/$(LDV_ONLINE_DIRNAME)
LDV_INSTALLED_ONLINE_CONF_DIR=$(LDV_INSTALLED_ONLINE_DIR)/$(LDV_ONLINE_CONF_DIRNAME)
LDV_INSTALLED_ONLINE_INSTALL_SERVER_SCRIPT=$(LDV_INSTALLED_ONLINE_DIR)/$(LDV_ONLINE_INSTALL_SERVER_SCRIPT_FILENAME)
LDV_INSTALLED_ONLINE_INSTALL_CLIENT_SCRIPT=$(LDV_INSTALLED_ONLINE_DIR)/$(LDV_ONLINE_INSTALL_CLIENT_SCRIPT_FILENAME)
LDV_INSTALLED_ONLINE_MIGRATE_SCRIPT=$(LDV_INSTALLED_ONLINE_DIR)/scripts/$(LDV_ONLINE_INSTALL_MIGRATE_SCRIPT_FILENAME)
LDV_INSTALLED_ONLINE_DBBACKUP_SCRIPT=$(LDV_INSTALLED_ONLINE_DIR)/scripts/$(LDV_ONLINE_INSTALL_DBBACKUP_SCRIPT_FILENAME)
LDV_INSTALLED_ONLINE_LIBS_DIR=$(LDV_INSTALLED_ONLINE_DIR)/$(LDV_ONLINE_LIBS_DIRNAME)
LDV_INSTALLED_ONLINE_DIST_DIR=$(LDV_INSTALLED_ONLINE_DIR)/$(LDV_ONLINE_DIST_DIRNAME)
LDV_INSTALLED_ONLINE_SERVER_SCRIPT=$(bindir)/$(LDV_ONLINE_SERVER_SCRIPT_FILENAME)
LDV_INSTALLED_ONLINE_CLIENT_SCRIPT=$(bindir)/$(LDV_ONLINE_CLIENT_SCRIPT_FILENAME)
LDV_INSTALLED_ONLINE_WWW_DIR=$(LDV_INSTALLED_ONLINE_DIR)/$(LDV_ONLINE_WWW_DIRNAME)
LDV_INSTALLED_ONLINE_SCRIPTS_DIR=$(LDV_INSTALLED_ONLINE_DIR)/$(LDV_ONLINE_SCRIPTS_DIRNAME)

.PHONY: all install clean

all:
	@cd $(LDV_ONLINE_SERVER_DIRNAME) && ant

install:
	@mkdir -p $(LDV_INSTALLED_ONLINE_DIR)	
	@mkdir -p $(LDV_INSTALLED_ONLINE_DIR)/logs
	@mkdir -p $(LDV_INSTALLED_ONLINE_CONF_DIR)
	@mkdir -p $(LDV_INSTALLED_ONLINE_LIBS_DIR)
	@mkdir -p $(LDV_INSTALLED_ONLINE_DIST_DIR)
	@mkdir -p $(LDV_INSTALLED_ONLINE_SCRIPTS_DIR)
	@mkdir -p $(LDV_INSTALLED_ONLINE_WWW_DIR)
	@cp -r $(LDV_ONLINE_CONF_DIRNAME)/* $(LDV_INSTALLED_ONLINE_CONF_DIR)
	@cp -r $(LDV_ONLINE_LIBS_DIR)/* $(LDV_INSTALLED_ONLINE_LIBS_DIR)
	@cp -r $(LDV_ONLINE_DIST_DIR)/* $(LDV_INSTALLED_ONLINE_DIST_DIR)
	@cp -r $(LDV_ONLINE_CLIENT_SCRIPT) $(LDV_INSTALLED_ONLINE_CLIENT_SCRIPT)
	@cp -r $(LDV_ONLINE_SERVER_SCRIPT) $(LDV_INSTALLED_ONLINE_SERVER_SCRIPT)
	@cp -r $(LDV_ONLINE_SCRIPTS_DIRNAME)/* $(LDV_INSTALLED_ONLINE_SCRIPTS_DIR)
	@cp -r $(LDV_ONLINE_WWW_DIRNAME)/* $(LDV_INSTALLED_ONLINE_WWW_DIR)
	@echo "Run $(LDV_INSTALLED_ONLINE_SCRIPTS_DIR)/$(LDV_ONLINE_INSTALL_SERVER_SCRIPT_FILENAME) to install server."
	@echo "Run $(LDV_INSTALLED_ONLINE_SCRIPTS_DIR)/$(LDV_ONLINE_INSTALL_CLIENT_SCRIPT_FILENAME) to install client."
	@echo "Run $(LDV_INSTALLED_ONLINE_MIGRATE_SCRIPT) to update database."

clean:
	@cd $(LDV_ONLINE_SERVER_DIRNAME) && ant clean
