srcdir=.

.PHONY: build-cmd-extractor rule-instrumentor drv-env-gen ldv-core ldv

target: pre-install build-cmd-extractor rule-instrumentor drv-env-gen ldv-core ldv
	echo "all installed"

pre-install:
	@$(call test_prefix)

define test_prefix
	if [ -n "$(prefix)" ]; then                                  \
		true;                                                \
	else                                                         \
		echo " "; 					     \
		echo "******************** ERROR *****************"; \
		echo " USAGE: prefix=/install/dir make            "; \
		echo "********************************************"; \
		echo " "; 					     \
		false;                                               \
        fi
endef
	

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

clean: pre-install
	@rm -fr $(prefix)/* 



