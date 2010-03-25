#!/bin/bash
FILEC=$1
DIR=`dirname $0`
$DIR/grep-all.sh $FILEC ldv_main && $DIR/grep-any.sh $FILEC open init probe
