#!/bin/sh


DRIVERS_DIR="/home/iceberg/Documents/linuxtesting/0032-serial-unsafe";
#DRIVERS_DIR="/home/iceberg/Documents/linuxtesting";
WORK_DIR="/home/iceberg/newrepo/tasktest";
KERNEL_DIR="/home/iceberg/newrepo/linux-2.6.32.10";
RULES_LIST="0032a,0039";
RULES_DB="/home/iceberg/kernel-rules";


export 

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

