INSTALL_DIR = `readlink -f ~`/opt/ldv

LDV_CORE_DIR = ldv-core
LDV_CORE_SCRIPT = ldv-core

ifndef prefix
prefix = `readlink -f $(INSTALL_DIR)`
endif


# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

.PHONY: install clean

install:
	if [[ ! -d $(prefix)/$(LDV_CORE_DIR) ]]; then mkdir -p $(prefix)/$(LDV_CORE_DIR); fi
	cp $(srcdir)/$(LDV_CORE_SCRIPT) $(prefix)/$(LDV_CORE_DIR)

clean:
	rm -fr $(prefix)/$(LDV_CORE_DIR)
