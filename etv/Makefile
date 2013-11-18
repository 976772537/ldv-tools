INSTALL_DIR = __install

# Error trace visualizer itself.
ETV = etv

# Directory for error trace visualizer auxiliary stuffs.
ETV_DIR = etv

# Directory containing converters for differenet error trace engines.
CONVERTERS = converters

# Directories with CSS, JS and Perl modules for ETV
CSS = css
JS = js
MODULES = modules

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
	cp $(ETV) $(prefix)/$(ETV_DIR)/
	ln -sf $(prefix)/$(ETV_DIR)/$(ETV) $(bindir)/$(ETV)
	mkdir -p $(prefix)/$(ETV_DIR)/$(CONVERTERS)
	cp -r $(CONVERTERS)/* $(prefix)/$(ETV_DIR)/$(CONVERTERS)
	mkdir -p $(prefix)/$(ETV_DIR)/$(CSS)
	cp -r $(CSS)/* $(prefix)/$(ETV_DIR)/$(CSS)
	mkdir -p $(prefix)/$(ETV_DIR)/$(JS)
	cp -r $(JS)/* $(prefix)/$(ETV_DIR)/$(JS)
	mkdir -p $(prefix)/$(ETV_DIR)/$(MODULES)
	cp -r $(MODULES)/* $(prefix)/$(ETV_DIR)/$(MODULES)

test:
	@echo The error trace visualizer doesn\'t have any test

clean:
	@echo The error trace visualizer doesn\'t require cleaning
