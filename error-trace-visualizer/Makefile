INSTALL_DIR = __install

ERROR_TRACE_VISUALIZER_SCRIPT = error-trace-visualizer.pl

# Standard Makefile section.
# Use root installation directory if no prefix was specified. 
ifndef prefix
prefix = `readlink -f $(INSTALL_DIR)`
endif
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
mandir = ${prefix}/man

# Phony targets.
.PHONY: install all

all: install

# Install needed executables to specified path.
install:
	if [ ! -d $(bindir) ]; then mkdir -p $(bindir) || exit 1; fi
	if [ ! -d $(mandir) ]; then mkdir -p $(mandir) || exit 1; fi
	cp $(ERROR_TRACE_VISUALIZER_SCRIPT) $(bindir) || exit 1
