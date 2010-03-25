CMD_UTILS_DIR = cmd-utils
AS_GCC_SCRIPT = as_gcc

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
	if [ ! -d $(prefix)/$(CMD_UTILS_DIR) ]; then mkdir -p $(prefix)/$(CMD_UTILS_DIR); fi
	cp $(srcdir)/$(AS_GCC_SCRIPT) $(prefix)/$(CMD_UTILS_DIR)

clean:
	@echo "cleaning - ok"
#	rm -fr $(prefix)/$(CMD_UTILS_DIR);
