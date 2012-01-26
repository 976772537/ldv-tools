INSTALL_DIR = __install

ETV = etv

# Standard Makefile section.
# Use root installation directory if no prefix was specified. 
ifndef prefix
prefix = `readlink -f $(INSTALL_DIR)`
endif
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
mandir = ${prefix}/man

# Phony targets.
.PHONY: all install test clean

# Default make action.
all:
	@echo The error trace visualizer doesn\'t require compilation

# Install needed executables to specified path.
install:
	mkdir -p $(bindir)
	mkdir -p $(mandir)
	cp $(ETV) $(bindir)

test:
	@echo The error trace visualizer doesn\'t have any test

clean:
	@echo The error trace visualizer doesn\'t require cleaning