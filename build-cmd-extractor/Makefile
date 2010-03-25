LDV_BUILD_CMD_EXTRACTOR_DIR = build-cmd-extractor
LDV_BUILD_CMD_EXTRACTOR_SCRIPT = build-cmd-extractor

# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

.PHONY: install clean

install:
	if [[ ! -d $(prefix)/$(LDV_BUILD_CMD_EXTRACTOR_DIR) ]]; then mkdir -p $(prefix)/$(LDV_BUILD_CMD_EXTRACTOR_DIR); fi	
	cp $(srcdir)/$(LDV_BUILD_CMD_EXTRACTOR_SCRIPT) $(prefix)/$(LDV_BUILD_CMD_EXTRACTOR_DIR)

clean:
	rm -fr $(prefix)/$(LDV_BUILD_CMD_EXTRACTOR_DIR)
