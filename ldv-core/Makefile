# Top level hierarchy
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
	cp $(srcdir)/ldv-core $(prefix)/ldv-core/

clean:
	rm -fr $(prefix)/ldv-core



