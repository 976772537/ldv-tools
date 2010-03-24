prefix=/opt/ldv
srcdir=.

.PHONY: build-cmd-extractor rule-instrumentor drv-env-gen ldv-core ldv

taget: build-cmd-extractor rule-instrumentor drv-env-gen ldv-core ldv
	echo "all installed"

build-cmd-extractor:
	@echo "installing build-cmd-extractor"
	@cd $(srcdir)/build-cmd-extractor; prefix=$(prefix) make install

rule-instrumentor:
	@cd $(srcdir)/rule-instrumentor; export prefix=$(prefix); make; export prefix=$(prefix); make install;


drv-env-gen:
	@echo "installing drv-env-gen"
	@cd $(srcdir)/drv-env-gen; prefix=$(prefix) make install

ldv-core:
	@echo "installing ldv-core"
	@cd $(srcdir)/ldv-core; prefix=$(prefix) make install

ldv:
	@echo "installing ldv"
	@cd $(srcdir)/ldv; prefix=$(prefix) make install

clean:
	@rm -fr /opt/ldv/*
