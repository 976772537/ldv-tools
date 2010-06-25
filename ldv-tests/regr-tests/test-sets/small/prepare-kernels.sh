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
cp ./kernels/*.tar.bz2 $target_dir 

