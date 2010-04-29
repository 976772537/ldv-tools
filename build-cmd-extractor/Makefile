LDV_BUILD_CMD_EXTRACTOR_DIR = build-cmd-extractor
LDV_BUILD_CMD_STREAM_DIVIDER_DIR = cmd-stream-divider
LDV_BUILD_CMD_EXTRACTOR_REPORTER_BIN = build-cmd-extractor-reporter
LDV_BUILD_CMD_STREAM_DIVIDER_BIN = $(LDV_BUILD_CMD_STREAM_DIVIDER_DIR)/dist/csd.jar
LDV_BUILD_CMD_EXTRACTOR_SCRIPT = build-cmd-extractor
LDV_BUILD_CMD_EXTRACTOR_GCC_SCRIPT = bce_gcc
LDV_BUILD_CMD_STREAM_DIVIDER_REPORTER_BIN = $(LDV_BUILD_CMD_STREAM_DIVIDER_DIR)/cmd-stream-divider-reporter

# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

.PHONY: all install clean

all:
	cd $(srcdir)/$(LDV_BUILD_CMD_STREAM_DIVIDER_DIR); ant

install:
	cd $(srcdir)/$(LDV_BUILD_CMD_STREAM_DIVIDER_DIR); ant
	if [ ! -d $(prefix)/$(LDV_BUILD_CMD_EXTRACTOR_DIR) ]; then mkdir -p $(prefix)/$(LDV_BUILD_CMD_EXTRACTOR_DIR); fi	
	cp $(srcdir)/$(LDV_BUILD_CMD_EXTRACTOR_SCRIPT) $(prefix)/$(LDV_BUILD_CMD_EXTRACTOR_DIR)
	cp $(srcdir)/$(LDV_BUILD_CMD_EXTRACTOR_GCC_SCRIPT) $(prefix)/$(LDV_BUILD_CMD_EXTRACTOR_DIR)
	cp $(srcdir)/$(LDV_BUILD_CMD_STREAM_DIVIDER_BIN) $(prefix)/$(LDV_BUILD_CMD_EXTRACTOR_DIR)
	cp $(srcdir)/$(LDV_BUILD_CMD_STREAM_DIVIDER_REPORTER_BIN) $(prefix)/$(LDV_BUILD_CMD_EXTRACTOR_DIR)
	cp $(srcdir)/$(LDV_BUILD_CMD_EXTRACTOR_REPORTER_BIN) $(prefix)/$(LDV_BUILD_CMD_EXTRACTOR_DIR)

clean:
	@cd $(srcdir)/$(LDV_BUILD_CMD_STREAM_DIVIDER_DIR); ant clean
