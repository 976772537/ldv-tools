# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
apachedir = ${WWW_DIR}
srcdir = .

.PHONY: all install clean

all:
	@echo "Ok"
	

install:
	@if [ ! -d "$(apachedir)" ]; then echo "Specify the WWW_DIR variable value."; exit 1; fi;
	@cp -r $(srcdir)/index.php $(apachedir)/ldv_online_service.php
	@cp -r $(srcdir)/ldv $(apachedir)/ldv

clean:
	@echo "Ok"

