#!/bin/bash
FILEC=$1
DIR=`dirname $0`
#echo $DIR
$DIR/grep-all.sh $FILEC ldv_main drm_gem_object_unreference
