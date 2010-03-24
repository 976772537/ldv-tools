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
	mkdir $(prefix)/build-cmd-extractor
	mkdir $(prefix)/build-cmd-extractor/bin/
	cp $(srcdir)/bin/build-cmd-extractor $(prefix)/build-cmd-extractor/bin/

clean:
	rm -fr $(prefix)/build-cmd-extractor;



