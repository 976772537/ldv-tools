#!/bin/bash
FILEC=$1
DIR=`dirname $0`
$DIR/grep-all.sh $FILEC ldv_main kmalloc && $DIR/grep-any.sh $FILEC usb_lock_device usb_unlock_device usb_trylock_device
