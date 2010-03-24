# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

target:
	ant

install:
	ant
	mkdir $(prefix)/drv-env-gen/
	cp $(srcdir)/dist/drv-env-gen.jar $(prefix)/drv-env-gen/

clean:
	rm -fr $(prefix)/drv-env-gen



