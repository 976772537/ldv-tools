INSTALL_DIR = __install

LDV_DIR = ldv
LDV_MAIN_SCRIPT = ldv
LDV_TASK_SCRIPT = ldv-task
LDV_KMANAGER_SCRIPT = ldv-kmanager
LDV_EXTRACTORS_DIR = extractors

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
	if [[ ! -d $(bindir) ]]; then mkdir -p $(bindir); fi
	cp $(srcdir)/$(LDV_MAIN_SCRIPT) $(bindir)
	if [[ ! -d $(prefix)/$(LDV_DIR) ]]; then mkdir -p $(prefix)/$(LDV_DIR); fi
	cp $(srcdir)/$(LDV_TASK_SCRIPT) $(prefix)/$(LDV_DIR)
	cp $(srcdir)/$(LDV_KMANAGER_SCRIPT) $(prefix)/$(LDV_DIR)
	cp -r $(srcdir)/$(LDV_EXTRACTORS_DIR) $(prefix)/$(LDV_DIR)/

clean:
	rm -fr $(prefix)/$(LDV_DIR);
	rm $(bindir)/$(LDV_MAIN_SCRIPT)
