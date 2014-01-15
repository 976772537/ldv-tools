DRV_ENV_GEN_DIR = drv-env-gen
DRV_ENV_GEN_CC = ldv_cc.jar
DRV_ENV_GEN_LD = ldv_ld.jar
DRV_ENV_GEN_WRAPPER = drv-env-gen
DRV_ENV_GEN_REPORTER = drv-env-gen-reporter
DRV_ENV_GEN_PROPERTIES = default.properties

# Top level hierarchy
exec_prefix = ${prefix}
# Pathname of directory to install the binary
bindir = ${exec_prefix}/bin
# Pathname of directory to install the man page
mandir = ${prefix}/share/man
srcdir = .

.PHONY: all install clean

all:
	ant

install:
	if [ ! -d $(prefix)/$(DRV_ENV_GEN_DIR) ]; then mkdir -p $(prefix)/$(DRV_ENV_GEN_DIR); fi
	cp $(srcdir)/dist/$(DRV_ENV_GEN_CC) $(prefix)/$(DRV_ENV_GEN_DIR)
	cp $(srcdir)/dist/$(DRV_ENV_GEN_LD) $(prefix)/$(DRV_ENV_GEN_DIR)
	cp $(srcdir)/$(DRV_ENV_GEN_WRAPPER) $(prefix)/$(DRV_ENV_GEN_DIR)
	cp $(srcdir)/$(DRV_ENV_GEN_REPORTER) $(prefix)/$(DRV_ENV_GEN_DIR)
	cp $(srcdir)/$(DRV_ENV_GEN_PROPERTIES) $(prefix)/$(DRV_ENV_GEN_DIR)

clean:
	ant clean
#	rm -fr $(prefix)/$(DRV_ENV_GEN_DIR)



