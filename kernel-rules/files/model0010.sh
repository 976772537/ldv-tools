#!/bin/bash
FILEC=$1
DIR=`dirname $0`
$DIR/grep-all.sh $FILEC ldv_main kmalloc request_irq
