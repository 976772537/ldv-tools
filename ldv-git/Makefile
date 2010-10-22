LDV_GIT_MAIN_SCRIPT_NAME = ldv-git
LDV_GIT_DIRNAME = ldv-git
LDV_BIN_DIRNAME = bin

# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

.PHONY: all install clean

all:
	echo "Ok.";

install:
	if [ ! -d $(prefix)/$(LDV_GIT_DIRNAME) ]; then mkdir -p $(prefix)/$(LDV_GIT_DIRNAME); fi
	cp -r $(srcdir)/* $(prefix)/$(LDV_GIT_DIRNAME)/
	mv $(prefix)/$(LDV_GIT_DIRNAME)/$(LDV_GIT_MAIN_SCRIPT_NAME) $(prefix)/$(LDV_BIN_DIRNAME)/

clean:
	echo "Ok."
