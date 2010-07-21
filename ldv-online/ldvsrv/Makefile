LDV_ONLINE_DIR = ldv-online 

# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .
tmpdir = ${TMP_DIR}

DEF_SERVER_CONF_FILE=$(prefix)/ldv-online/conf/server.conf
DEF_NODE_CONF_FILE=$(prefix)/ldv-online/conf/client.conf


.PHONY: all install clean

all:
	ant

install: all
	@if [ ! -n "$(tmpdir)" ]; then echo "Specify the TMP_DIR variable value."; exit 1; fi;
	@if [ ! -d "$(tmpdir)" ]; then mkdir -p $(tmpdir)/run; fi;
	@if [ ! -d "$(prefix)/ldv-online" ]; then mkdir $(prefix)/ldv-online; fi;
	@cp -r $(srcdir)/dist $(prefix)/ldv-online/
	@cp -r $(srcdir)/conf $(prefix)/ldv-online/
	@cp -r $(srcdir)/bin/* $(prefix)/bin/
	@cp -r $(srcdir)/lib $(prefix)/ldv-online/
	@sed -i -e 's|WorkDir=/home/iceberg/ldvtest/ldv-online/client|WorkDir=$(tmpdir)|g' $(DEF_NODE_CONF_FILE);
	@sed -i -e 's|LDVInstalledDir=/opt/ldv|LDVInstalledDir=$(prefix)|g' $(DEF_SERVER_CONF_FILE);

clean:
	@ant clean

