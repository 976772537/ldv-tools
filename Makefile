
# Phony targets.
.PHONY: all install

all:
	@echo This project doesn\'t require compilation.

# Install needed executables to specified path.
install:
	mkdir -p build
	cp test.txt build
	cp test.py build
	touch build/tmp2.txt
clean:
	rm -rf build
