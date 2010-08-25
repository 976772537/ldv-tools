#!/bin/bash
function usage {
cat 1>&2 <<usage_ends
Usage:
        make-drivers.sh /dir/to/built/to kernelsrc
Example:
	make-drivers.sh /root/mutilin/ldv-tools-test/kernels/linux-2.6.31.6
  
usage_ends
exit 1;
}
BUILTDIR=$1
test -d $BUILTDIR || (echo "dir to built does not exists $BUILTDIR" && usage)
KERNELSRC=$2
test -d $KERNELSRC || (echo "kernel src does not exists $KERNELSRC" && usage)

for i in `find $BUILTDIR -name "test-*"`
do
	DRVDIR=$i;
	make -C $KERNELSRC M=`pwd`/$i modules || exit 1
done
