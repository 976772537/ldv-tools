#!/bin/sh
#
# Copyright (c) 2010-2020 ISPRAS Moscow, Russia.
#
# Author: Alexandr Strakh <strakh@ispras.ru>
#
#

#####################################################
#
# Before include this script, setup variables:
#
#  $LDV_DEBUG    - debug level (10..100)
#  $LOG_PREFIX   - instrument log prefix
#  $USAGE_STRING - usage string for tool
# 
#####################################################

ldv_print() {
	if [ $LDV_DEBUG -le 0 ]; then if [ -n "`echo $1 | grep WARNING`" -o -n "`echo $1 | grep NORMAL`" -o -n "`echo $1 | grep INFO`" -o -n "`echo $1 | grep DEBUG`" -o -n "`echo $1 | grep TRACE`" -o -n "`echo $1 | grep ALL`" ]; then return; fi;
	elif [ $LDV_DEBUG -le 10 ]; then if [ -n "`echo $1 | grep INFO`" -o -n "`echo $1 | grep DEBUG`" -o -n "`echo $1 | grep TRACE`" -o -n "`echo $1 | grep ALL`" ]; then return; fi;
	elif [ $LDV_DEBUG -le 20 ]; then if [ -n "`echo $1 | grep DEBUG`" -o -n "`echo $1 | grep TRACE`" -o -n "`echo $1 | grep ALL`" ]; then return; fi;
	elif [ $LDV_DEBUG -le 30 ]; then if [ -n "`echo $1 | grep TRACE`" -o -n "`echo $1 | grep ALL`" ]; then return; fi;
	elif [ $LDV_DEBUG -le 40 ]; then if [ -n "`echo $1 | grep ALL`" ]; then return; fi; fi;
	if [ $LDV_DEBUG -ge 30 ]; then PRINT_DIGRAPH_OPTION="--print-digraph"; fi;
	echo "$LOG_PREFIX$1";
}
if [ ! -n "$LDV_DEBUG" ]; then LDV_DEBUG=10; fi;

print_usage_and_exit() {
		ldv_print "NORMAL: USAGE: $USAGE_STRING";
		exit 1;
}

