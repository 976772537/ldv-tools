LDV_ONLINE_DIR = ldv-online 

# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

.PHONY: all install clean

all:
	@ant

install: all
	@if [ ! -d $(prefix)/$(LDV_ONLINE_DIR) ]; then mkdir -p $(prefix)/$(LDV_ONLINE_DIR); fi
	@cp -r $(srcdir)/dist $(prefix)/$(LDV_ONLINE_DIR)
	@cp -r $(srcdir)/conf $(prefix)/$(LDV_ONLINE_DIR)
	@cp -r $(srcdir)/bin/* $(prefix)/bin/
	@cp -r $(srcdir)/lib $(prefix)/$(LDV_ONLINE_DIR)

clean:
	@ant clean

