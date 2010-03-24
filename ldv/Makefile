# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

install:
	cp $(srcdir)/ldv $(bindir)
	mkdir $(prefix)/ldv
	cp $(srcdir)/ldv-task $(prefix)/ldv/
	cp $(srcdir)/ldv-kmanager $(prefix)/ldv/
	cp -r $(srcdir)/extractors $(prefix)/ldv/

clean:
	rm -fr $(prefix)/ldv;
	rm $(bindir)/ldv



