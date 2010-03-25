#!/bin/bash
FILEC=$1
DIR=`dirname $0`
#echo $DIR
$DIR/grep-all.sh $FILEC ldv_main && $DIR/grep-any.sh $FILEC list_add list_del list_add_tail list_replace  list_replace_init list_del_init list_move list_move_tail 
