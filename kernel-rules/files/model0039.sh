#!/bin/bash
FILEC=$1
DIR=`dirname $0`
#echo $DIR
$DIR/grep-all.sh $FILEC ldv_main && $DIR/grep-any.sh $FILEC spin_lock spin_unlock
