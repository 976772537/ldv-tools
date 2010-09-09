#!/bin/bash
function usage {
cat 1>&2 <<usage_ends
Usage:
        pack-drivers.sh /dir/to/save/to

Packs test drivers into the directory specified.  Creates it if necessary.
Searches for drivers in predefined directory './drivers/' with predefined prefix 'test-'.
usage_ends
exit 1;
}

source_dir=`dirname $0`
echo "source_dir=$source_dir"
target_dir=$1
test -z "$target_dir" && usage
mkdir -p "$target_dir"

test ! -d "./drivers" && echo "Currently script should be run from $source_dir" && exit 1;

for i in `find ./drivers/ -name "test-*"`
do
	DRVDIR=$i;
	DRVARCH=`echo $DRVDIR | sed 's/\.\/drivers\///g' | sed 's/\//--/g'`;
	tar cvfj $target_dir/$DRVARCH.tar.bz2 $DRVDIR
done
