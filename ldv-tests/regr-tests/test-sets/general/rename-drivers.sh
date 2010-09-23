#!/bin/bash
function usage {
cat 1>&2 <<usage_ends
Usage:
        rename-drivers.sh /dir/from/copy /dir/to/save/to

Renames test drivers - adds directory names to archive name and copies them into the directory specified.  Creates it if necessary.
usage_ends
exit 1;
}

source_dir=`dirname $0`
#echo "source_dir=$source_dir"
orig_dir=$1
if `test -z "$orig_dir"`; then echo "specify non empty archives directory" && usage; fi
if [ ! -d "$orig_dir" ]; then echo "specify existing archives directory" && usage; fi

target_dir=$2
if `test -z "$target_dir"`; then echo "specify destination directory" && usage; fi
mkdir -p "$target_dir"

for i in `find $orig_dir -name "*.tar.bz2"`
do
	ORIGDRV=$i;
	DRVARCH=`echo $ORIGDRV | sed 's/\.\///g' | sed 's/\//--/g'`;
	#echo $DRVARCH
	cp $ORIGDRV $target_dir/$DRVARCH.tar.bz2
done

