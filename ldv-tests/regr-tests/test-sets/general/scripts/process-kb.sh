#!/bin/bash
function usage {
cat 1>&2 <<usage_ends
Usage:
        process-kb.sh kb00XX.txt /dir/to/save/to prefix kernelsrc
Example:
	process-kb.sh kb0032.txt ./drivers/verdict-unsafe/ "test-0032-verdict" /root/mutilin/ldv-tools-test/kernels/linux-2.6.31.6
  
usage_ends
exit 1;
}

KBFILE=$1
test -e "$KBFILE" || (echo "kb file not found $KBFILE" && usage)
RESPATH=$2
test -d $RESPATH || (echo "res path does not exists $RESPATH" && usage)
INPUTPREFIX=$3;
test -n $INPUTPREFIX || (echo "empty prefix $INPUTPREFIX" && usage)
KERNELSRC=$4
test -d $KERNELSRC || (echo "kernel src does not exists $KERNELSRC" && usage)

source_dir=`dirname $0`
echo "source_dir=$source_dir"

while read line;
do
	#echo $line;
	if [ -n "$line" ]
	then
		DRVPATH=`echo $line | sed 's/\(.*\)==.*/\1/g'`;
		echo drv=$DRVPATH;
		VERDICT2=`echo $line | sed 's/.*==\(.*\)--.*/\1/g'`;
		VERDICT=`echo $VERDICT2`;
		echo verd=$VERDICT
		$source_dir/extract-driver.sh $RESPATH $INPUTPREFIX $KERNELSRC $DRVPATH $VERDICT
	fi
done < $KBFILE


