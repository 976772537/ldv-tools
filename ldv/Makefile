LDV_DIR = ldv
LDV_MAIN_SCRIPT = ldv
LDV_TASK_SCRIPT = ldv-task
LDV_KMANAGER_SCRIPT = ldv-kmanager
LDV_EXTRACTORS_DIR = extractors
LDV_REPORTER = ldv-task-reporter

# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

.PHONY: all install clean

all:
	@echo "building - ok";

install:
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir); fi
	cp $(srcdir)/$(LDV_MAIN_SCRIPT) $(bindir)
	if [ ! -d $(prefix)/$(LDV_DIR) ]; then mkdir -p $(prefix)/$(LDV_DIR); fi
	cp $(srcdir)/$(LDV_TASK_SCRIPT) $(prefix)/$(LDV_DIR)
	cp $(srcdir)/$(LDV_KMANAGER_SCRIPT) $(prefix)/$(LDV_DIR)
	cp $(srcdir)/$(LDV_REPORTER) $(prefix)/$(LDV_DIR)
	cp -r $(srcdir)/$(LDV_EXTRACTORS_DIR) $(prefix)/$(LDV_DIR)/

clean:
	@echo "cleaning - ok"
#	rm -fr $(prefix)/$(LDV_DIR);
#	rm $(bindir)/$(LDV_MAIN_SCRIPT)
