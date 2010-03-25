#!/bin/bash
FILEC=$1
DIR=`dirname $0`
$DIR/grep-all.sh $FILEC ldv_main && $DIR/grep-any.sh $FILEC blk_init_queue blk_cleanup_queue
