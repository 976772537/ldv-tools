
# Phony targets.
.PHONY: all install

all:
	@echo This project doesn\'t require compilation.

# Install needed executables to specified path.
install:
	mkdir -p ../build-project
	cp test.txt ../build-project
	cp test.py ../build-project
