# Directory with CIF and Aspectator sources, objects and executables.
CIF_DIR = cif

# Directory RI, CIF and Aspectator stuff to be installed.
RI_DIR = ri

# Standard directories for installation of executables and manuals.
exec_prefix = $(shell readlink -f $(prefix))
bindir = $(exec_prefix)/bin
mandir = $(prefix)/man

.PHONY: all install test clean

# Building, testing and cleaning aren't needed for RI itself. Just for CIF.
all:
	@echo "Begin to build CIF"
	make -C $(CIF_DIR) $@
	@echo "RI doesn't require build itself"

# Before installation perform build.
install:
	@echo "Begin to install CIF"
	prefix=$(exec_prefix)/$(RI_DIR) make -C $(CIF_DIR) $@
	@mkdir -p $(bindir)
	@mkdir -p $(mandir)
	cp rule-instrumentor.pl $(bindir)
	cp ri.aspect $(exec_prefix)/$(RI_DIR)
	@echo "Create link to CIF inside directory containing main LDV executables"
	ln -sf $(exec_prefix)/$(RI_DIR)/bin/cif $(bindir)/cif

test:
	@echo "Begin to test CIF"
	make -C $(CIF_DIR) $@
	@echo "RI hasn't tests at the moment"

clean:
	@echo "Begin to clean CIF"
	make -C $(CIF_DIR) $@
	@echo "RI hasn't build files"
