# Standard directory for installation of main LDV executables.
bindir = $(prefix)/bin

.PHONY: all install test clean

all:
	@gcc res-manager.c -o res-manager

install: all
	@mkdir -p $(bindir)
	@cp res-manager $(bindir)

test:
	#@echo "Resource Manager hasn't tests at the moment"

clean:
	@rm -f res-manager 
