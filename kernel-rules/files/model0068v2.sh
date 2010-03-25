#!/bin/bash
FILEC=$1
DIR=`dirname $0`
#echo $DIR
$DIR/grep-all.sh $FILEC ldv_main && $DIR/grep-any.sh $FILEC usb_submit_urb usb_unlink_urb usb_alloc_urb usb_free_urb 
