#!/bin/bash
function usage {
cat 1>&2 <<usage_ends
Usage:
        extract-driver.sh /dir/to/save/to prefix kernelsrc drvpath verdict
Example:
	extract-driver.sh ./drivers/verdict-unsafe/ "test-0032-verdict" /root/mutilin/ldv-tools-test/kernels/linux-2.6.31.6 drivers/scsi/libfc/fc_disc.c unsafe
  
usage_ends
exit 1;
}

RESPATH=$1
test -d $RESPATH || (echo "res path does not exists $RESPATH" && usage)
INPUTPREFIX=$2;
test -n $INPUTPREFIX || (echo "empty prefix $INPUTPREFIX" && usage)
KERNELSRC=$3
test -d $KERNELSRC || (echo "kernel src does not exists $KERNELSRC" && usage)

DRVPATH=$4
test -n $DRVPATH || (echo "empty drvpath $DRVPATH" && usage)
VERDICT=$5
test -n $VERDICT || (echo "empty verdict $VERDICT" && usage)

PREFIX="$INPUTPREFIX-$VERDICT";
if `test -e $KERNELSRC/$DRVPATH`; 
then
	DRVDIR=`dirname $KERNELSRC/$DRVPATH`;
	DRVRES=`echo $DRVPATH | sed 's/\//--/g'`;
	FINALPATH="$RESPATH/$PREFIX-$DRVRES";
	mkdir -p $FINALPATH;
	cp $KERNELSRC/$DRVPATH $FINALPATH;
	if `ls $DRVDIR/*.h > /dev/null 2>&1`;
	then
		cp $DRVDIR/*.h $FINALPATH;
	fi
	DRVOBJ=`basename $DRVPATH | sed 's/\.c/\.o/g'`;
	echo "obj-m := $DRVOBJ" > $FINALPATH/Makefile;
fi
