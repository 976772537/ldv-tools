LDV_SHARED_DIRNAME = shared
LDV_SHARED_SHELL_DIRNAME = sh
LDV_SHARED_SHELL = $(LDV_SHARED_DIRNAME)/$(LDV_SHARED_SHELL_DIRNAME)

# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = ../../

.PHONY: all install clean

all:
	@echo "Shared scripts - ok.";

install:
	if [ ! -d $(prefix)/$(LDV_SHARED_DIRNAME) ]; then mkdir -p $(prefix)/$(LDV_SHARED_DIRNAME); fi;
	cp -r $(srcdir)/$(LDV_SHARED_SHELL) $(prefix)/$(LDV_SHARED_SHELL);

clean:
	@echo "Cleaning - ok.";
