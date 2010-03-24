INSTALL_DIR = __install

DRV_ENV_GEN_DIR = drv-env-gen
DRV_ENV_GEN_JAR = drv-env-gen.jar

ifndef prefix
prefix = `readlink -f $(INSTALL_DIR)`
endif

# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

.PHONY: install clean

install:
	ant
	if [[ ! -d $(prefix)/$(DRV_ENV_GEN_DIR) ]]; then mkdir -p $(prefix)/$(DRV_ENV_GEN_DIR); fi
	cp $(srcdir)/dist/$(DRV_ENV_GEN_JAR) $(prefix)/$(DRV_ENV_GEN_DIR)

clean:
	rm -fr $(prefix)/$(DRV_ENV_GEN_DIR)
	ant clean



