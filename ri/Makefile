# Directory with CIF and Aspectator sources, objects and executables.
CIF_DIR = cif

# Directory RI, CIF and Aspectator stuff to be installed.
RI_DIR = ri

# Standard directory for installation of main LDV executables.
bindir = $(prefix)/bin

.PHONY: all install test clean

# Building, testing and cleaning aren't needed for RI itself. Just for CIF.
all:
	@echo "Begin to build CIF"
	make -C $(CIF_DIR) $@
	@echo "RI doesn't require build itself"

# Do not perform build before installation since RI doesn't need this while CIF
# does it itself (otherwise CIF will be build twice).
install:
	@echo "Begin to install CIF"
	prefix=$(prefix)/$(RI_DIR) make -C $(CIF_DIR) $@
	@mkdir -p $(bindir)
	cp rule-instrumentor.pl $(bindir)
	cp ri.aspect $(prefix)/$(RI_DIR)
	@echo "Create link to CIF inside directory containing main LDV executables"
	ln -sf $(prefix)/$(RI_DIR)/bin/cif $(bindir)/cif

test:
	@echo "Begin to test CIF"
	make -C $(CIF_DIR) $@
	@echo "RI hasn't tests at the moment"

clean:
	@echo "Begin to clean CIF"
	make -C $(CIF_DIR) $@
	@echo "RI hasn't build files"
