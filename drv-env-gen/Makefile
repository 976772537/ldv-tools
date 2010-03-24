# Top level hierarchy
prefix = /usr/local
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

target:
	ant

install:
	cp $(srcdir)/dist/drv-env-gen.jar $(bindir)/

clean:
	rm $(bindir)/dist/drv-env-gen.jar



