#!/bin/bash
# Standard directory for installation of main LDV executables.
bindir = $(prefix)/bin
tests = tests
build = build

.PHONY: all install test clean

all:
	@mkdir -p ${build}
	@gcc -std=gnu99 -Wall -Wundef -Wstrict-prototypes -Wno-trigraphs -Wno-sign-compare -Wdeclaration-after-statement -Wno-pointer-sign -Werror  res-manager.c -o build/res-manager
	@./setup-ldv-cgroup
	
install:
	@mkdir -p $(bindir)
	@cp build/res-manager $(bindir)
	@./setup-ldv-cgroup -i

test:
	@mkdir -p ${build}
	@mkdir -p ${build}/${tests}/memory
	@mkdir -p ${build}/${tests}/errors
	@mkdir -p ${build}/${tests}/time
	
	@#cd ${tests}; for file in time/*; do echo "got file $file"; done
	
	@gcc ${tests}/test_script.c -o ${build}/${tests}/test_script
	@gcc ${tests}/time/real.c -o ${build}/${tests}/time/real
	@gcc ${tests}/time/real_childs_2.c -o ${build}/${tests}/time/real_childs_2
	@gcc ${tests}/time/real_childs_1.c -o ${build}/${tests}/time/real_childs_1
	@gcc ${tests}/time/sys.c -o ${build}/${tests}/time/sys
	@gcc ${tests}/time/sys_childs_2.c -o ${build}/${tests}/time/sys_childs_2
	@gcc ${tests}/time/sys_childs_1.c -o ${build}/${tests}/time/sys_childs_1
	@gcc ${tests}/time/user.c -o ${build}/${tests}/time/user
	@gcc ${tests}/time/user_childs_2.c -o ${build}/${tests}/time/user_childs_2
	@gcc ${tests}/time/user_childs_1.c -o ${build}/${tests}/time/user_childs_1
	@gcc ${tests}/time/sequential_childs_1.c -o ${build}/${tests}/time/sequential_childs_1
	@gcc ${tests}/time/sequential_childs_2.c -o ${build}/${tests}/time/sequential_childs_2
	@gcc ${tests}/memory/limit.c -o ${build}/${tests}/memory/limit
	@gcc ${tests}/memory/limit_child.c -o ${build}/${tests}/memory/limit_child
	@gcc ${tests}/memory/limit_child.c -o ${build}/${tests}/memory/limit_child
	@gcc ${tests}/errors/return.c -o ${build}/${tests}/errors/return
	@gcc ${tests}/errors/sig_num.c -o ${build}/${tests}/errors/sig_num
	@gcc ${tests}/errors/sig_ign.c -o ${build}/${tests}/errors/sig_ign
	
	@gcc ${tests}/res_manager_in_res_manager.c -o ${build}/${tests}/res_manager_in_res_manager
	@cd ${build}/${tests}; ./test_script ../res-manager;

clean:
	@rm -rf ${build}

