#!/bin/bash
function usage {
cat 1>&2 <<usage_ends
Usage:
        prepare-kernels.sh /dir/to/save/to

Packs test kernels into the directory specified.  Creates it if necessary.
usage_ends
exit 1;
}
target_dir=$1

test -z "$target_dir" && usage
mkdir -p "$target_dir"
MYKERNEL="mykernel-1-2.6.32.15"
tar xfj ./kernels/$MYKERNEL.tar.bz2 -C $target_dir || exit 1
cp -r ./kernels/kernel-drivers/mydrv/ $target_dir/$MYKERNEL/ || exit 1
cd $target_dir && tar cfj $MYKERNEL.tar.bz2 $MYKERNEL/ || exit 1
#cp ./kernels/*.tar.bz2 $target_dir 

