
# Phony targets.
.PHONY: all install

all:
	@echo This project doesn\'t require compilation.

# Install needed executables to specified path.
install:
	touch tmp2.txt
	mkdir -p build
	cp test.txt build
	cp test.py build
clean:
	rm -rf build
