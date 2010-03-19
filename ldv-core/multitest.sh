#!/bin/sh


DRIVERS_DIR="/home/iceberg/Documents/linuxtesting/0032-serial-unsafe";
#DRIVERS_DIR="/home/iceberg/Documents/linuxtesting";
WORK_DIR="/home/iceberg/newrepo/tasktest";
KERNEL_DIR="/home/iceberg/newrepo/linux-2.6.32.10";
RULES_LIST="32_1";
RULES_DB="/home/iceberg/kernel-rules";

export LDV_ASPECTATOR="/home/iceberg/projects/LDV/ldv/model/instrumenter/llvm-2.6/aspectator/aspectator.sh"
export LDV_LLVM_C_BACKEND="/usr/share/llvm/llvm-2.6-bin/bin/llc"
export LDV_LLVM_GCC="/usr/share/llvm/llvm-gcc-2.6-bin/bin/gcc"
export LDV_LLVM_LINKER="/usr/share/llvm/llvm-2.6-bin/bin/llvm-link"

rm -fr $WORK_DIR/*;

k=1;
#for i in `find $DRIVERS_DIR -regex '.*\.tar\.bz2$' | grep driver3`; do
for i in `find $DRIVERS_DIR -regex '.*\.tar\.bz2$'`; do
	echo "********** run test for driver: $i:$k ************";
	CURRENT_TASK_DIR="$WORK_DIR/$k";
	mkdir $CURRENT_TASK_DIR;
	sh ldv.sh $CURRENT_TASK_DIR $KERNEL_DIR $i $RULES_DB $RULES_LIST;
	let k=$k+1;
done;

