LDV_CORE_DIR = ldv-core
LDV_CORE_SCRIPT = ldv-core
LDV_CORE_REPORTER = ldv-core-reporter
LDV_FAST_FIX_CMDSTREAM = fast_fix_cmdstream.pl

# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

.PHONY: all install clean

all:
	@echo "building - Ok"

install:
	if [ ! -d $(prefix)/$(LDV_CORE_DIR) ]; then mkdir -p $(prefix)/$(LDV_CORE_DIR); fi
	cp $(srcdir)/$(LDV_CORE_SCRIPT) $(prefix)/$(LDV_CORE_DIR)
	cp $(srcdir)/$(LDV_CORE_REPORTER) $(prefix)/$(LDV_CORE_DIR)
	cp $(srcdir)/$(LDV_FAST_FIX_CMDSTREAM) $(prefix)/$(LDV_CORE_DIR)

clean:
	@echo "cleaning - ok"
#	rm -fr $(prefix)/$(LDV_CORE_DIR)
