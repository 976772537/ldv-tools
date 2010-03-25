#!/bin/bash
FILEC=$1
DIR=`dirname $0`
$DIR/grep-all.sh $FILEC ldv_main kmalloc && $DIR/grep-any.sh $FILEC spin_lock spin_unlock
