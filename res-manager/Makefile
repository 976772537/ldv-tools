# Standard directory for installation of main LDV executables.
bindir = $(prefix)/bin
tests = 

.PHONY: all install test clean

all:
	@gcc res-manager.c -o res-manager
	
install: all
	@mkdir -p $(bindir)
	@cp res-manager $(bindir)

test: all
	@mkdir -p build
	@mkdir -p build/memory
	@mkdir -p build/errors
	@mkdir -p build/time
	
	@gcc tests/test_script.c -o build/test_script
	
	@gcc tests/time/real.c -o build/time/real
	@gcc tests/time/real_h_2.c -o build/time/real_h_2
	@gcc tests/time/real_h.c -o build/time/real_h
	@gcc tests/time/sys.c -o build/time/sys
	@gcc tests/time/sys_h_2.c -o build/time/sys_h_2
	@gcc tests/time/sys_h.c -o build/time/sys_h
	@gcc tests/time/user.c -o build/time/user
	@gcc tests/time/user_h_2.c -o build/time/user_h_2
	@gcc tests/time/sequential_childs_1.c -o build/time/sequential_childs_1
	@gcc tests/time/sequential_childs_2.c -o build/time/sequential_childs_2
	@gcc tests/time/user_h.c -o build/time/user_h
	
	@gcc tests/memory/limit.c -o build/memory/limit
	@gcc tests/memory/limit_child.c -o build/memory/limit_child
	
	@gcc tests/errors/return.c -o build/errors/return
	@gcc tests/errors/sig_num.c -o build/errors/sig_num
	
	build/test_script --run ./res-manager
	
clean:
	@rm -f res-manager 
	@rm build/time/*
	@rm build/memory/*
	@rm build/errors/*
	@rmdir build/time
	@rmdir build/errors
	@rmdir build/memory
	@rm build/*
	@rmdir build


