LDV_ONLINE_DIR = ldv-online 

# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .
tmpdir = ${TMP_DIR}
webdir = ${WEB_DIR}

DEF_SERVER_CONF_FILE=$(prefix)/ldv-online/conf/server.conf
DEF_NODE_CONF_FILE=$(prefix)/ldv-online/conf/client.conf


.PHONY: all install clean

all:
	@echo "Ok";

install: all
	@if [ ! -d $(prefix)/$(LDV_ONLINE_DIR) ]; then mkdir -p $(prefix)/$(LDV_ONLINE_DIR); fi
	@if [ ! -n "$(tmpdir)" ]; then echo "Specify the TMP_DIR variable value."; exit 1; fi;
	@if [ ! -d "$(tmpdir)" ]; then mkdir $(tmpdir)/run; fi;
	@if [ ! -n "$(webdir)" ]; then echo "Specify the WEB_DIR variable value."; exit 1; fi;
	@if [ ! -d "$(tmpdir)" ]; then $(webdir) not exists; fi;
	@cp -r $(srcdir)/index.php $(webdir)/ldv_online_service.php
	@cp -r $(srcdir)/ldv $(webdir)/
	@sed -i -e 's|WorkDir=/home/iceberg/ldvtest/ldv-online/serv|WorkDir=$(tmpdir)|g' $(DEF_SERVER_CONF_FILE);
	@sed -i -e 's|ModelsDBPath=/home/iceberg/ldv-tools/kernel-rules/model-db.xml|ModelsDBPath=$(prefix)/kernel-rules/model-db.xml|g' $(DEF_SERVER_CONF_FILE);
	@sed -i -e 's|RulesDBPath=/home/iceberg/ldv-tools/kernel-rules/rules/DRVRULES_en.trl|RulesDBPath=$(prefix)/kernel-rules/rules/DRVRULES_en.trl|g' $(DEF_SERVER_CONF_FILE);
	@sed -i -e 's|ErrorTraceVisualizer=/opt/ldv/bin/error-trace-visualizer.pl|ErrorTraceVisualizer=$(prefix)/bin/error-trace-visualizer.pl|g' $(DEF_SERVER_CONF_FILE);
	@sed -i -e 's|WSTempDir=/opt/ldv/bin/error-trace-visualizer.pl|WSTempDir=$(tmpdir)|g' $(DEF_SERVER_CONF_FILE);
	@sed -i -e 's|WSInit(PATH_TO_CONF);|WSInit("$(DEF_SERVER_CONF_FILE)");|g' $(webdir)/ldv_online_service.php;
	@echo " Make sure you did the following:";
	@echo "  1. Install mysql server.";
	@echo "  2. Start mysql server daemon: \"sudo /etc/init.d/mysqld\".";
	@echo "  3. Connect to db server as root like this: \"mysql -u root ...\".";
	@echo "  4. Create db for stats: \"CREATE DATABASE dbanem;\".";
	@echo "  5. Create user for stats db: \"CREATE USER 'dbuser'@'dbhost' IDENTIFIED BY 'dbpass';\".";
	@echo "  6. Add priviledges: \"GRANT ALL PRIVILEGES ON dbname.* TO 'dbuser'@'dbhost' WITH GRANT OPTION;\".";
	@echo "  7. Update privileges: \"FLUSH PRIVILEGES;\".";
	@echo "  8. Write all parameters (dbname, dbhost, dbuser, dbpass) to $(DEF_SERVER_CONF_FILE) script.";

clean:
	@ant clean

