#!/bin/bash
FILEC=$1
DIR=`dirname $0`
$DIR/grep-all.sh $FILEC ldv_main && $DIR/grep-any.sh $FILEC usb_alloc_urb usb_set_intfdata usb_fill_control_urb usb_fill_bulk_urb usb_fill_int_urb usb_submit_urb
