# Top level hierarchy
prefix = /usr/local
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

target:
	@echo "ok";

install:
	mkdir $(prefix)/ldv-core
	mkdir $(prefix)/ldv-core/bin
	cp $(srcdir)/bin/ldv-core $(prefix)/ldv-core/bin/

clean:
	rm -fr $(prefix)/ldv-core;



