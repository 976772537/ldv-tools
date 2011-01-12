#!/bin/bash

KERNEL_MAKEFILE_ABS=`readlink -f $KERNEL_MAKEFILE`;
if [ $? -ne 0 ]; then
        ldv_print "ERROR: Can not find makefile."
        exit 1;
fi;
KERNEL_MAKEFILE_DIR=`dirname $KERNEL_MAKEFILE_ABS`;
# prepare it
cd $KERNEL_MAKEFILE_DIR;

#
# test kernel version
#
k_version=`cat $KERNEL_MAKEFILE_ABS | grep -E "^VERSION = 2\$" | sed 's/\VERSION = //g'`
k_patchlevel=`cat $KERNEL_MAKEFILE_ABS | grep -E "^PATCHLEVEL = 6\$" | sed 's/\PATCHLEVEL = //g'`
k_sublevel=`cat $KERNEL_MAKEFILE_ABS | grep -E "^SUBLEVEL = [0-9][0-9]?\$" | sed 's/\SUBLEVEL = //g'`
k_kernelversion="$k_version.$k_patchlevel.$k_sublevel"
kernel_makefile_patch="$LDV_HOME/ldv/extractors/linux-vanilla/ldv-git.patch";
kernel_final_link_patch="$LDV_HOME/ldv/extractors/linux-vanilla/fix_bigobj.pl -k ";
ldv_print "NORMAL: Kernel version is: $k_kernelversion";

KERNEL_MAKEFILE_BUILD=$KERNEL_MAKEFILE_DIR"/scripts/Makefile.build";
if [ ! -f "$KERNEL_MAKEFILE_BUILD" ]; then
	ldv_print "ERROR: Can't find kernel makefile: \"$KERNEL_MAKEFILE_BUILD\".";
	exit 1;
fi;
#
# create backup for ./scripts/Makefile.build
#
KERNEL_BACKUP_MAKEFILE_BUILD=$KERNEL_MAKEFILE_DIR"/scripts/Makefile.build.bcebackup";
cp $KERNEL_MAKEFILE_BUILD $KERNEL_BACKUP_MAKEFILE_BUILD;
if [ $? -ne 0 ]; then
	ldv_print "ERROR: Failed to copy Makefile: \"$KERNEL_MAKEFILE_BUILD\" to \"$KERNEL_BACKUP_MAKEFILE_BUILD\".";
	exit 1;
fi;


#
# if options not set =>
#   i am set default allmodconfig
#
if [ -n "$LDVGIT_CONFIG_CMD" ]; then
	eval $LDVGIT_CONFIG_CMD;
else 
	make allyesconfig;
fi;
if [ $? -ne 0 ]; then
        ldv_print "ERROR: make allyesconfig failed."
        exit 1;
fi;
make init;
if [ $? -ne 0 ]; then
        ldv_print "ERROR: make init failed."
        exit 1;
fi;




#
# Patch it for ldv-git
#
ldv_print "NORMAL: Patching kernel makefile for ldv-git..."
ldv_print "DEBUG: patch -i $kernel_makefile_patch -p1 -d $KERNEL_MAKEFILE_DIR;";
patch -i $kernel_makefile_patch -p1 -d $KERNEL_MAKEFILE_DIR;
if [ $? -ne 0 ]; then 
	ldv_print "WARNING: Can't apply makefile patch for your kernel.";
fi;

#
# test if a FILE exists and write permission is granted or not
#
if [ ! -w "$KERNEL_MAKEFILE_BUILD" ]; then
	ldv_print "ERROR: Kernel Makefile.build: \"$KERNEL_MAKEFILE_BUILD\" -  not writable.";
	exit 1;
fi;

#
# Read state - if it null then we have state "BEOFRE_APPLY"
#

ldv_print "INFO: Patching other makefile parts...";
sed -i -e "s/^cmd_cc_o_c = \$(CC) \$(c_flags) -c -o \$(@D)\/\.tmp_\$(@F) \$</cmd_cc_o_c = \$(LDV_HOME)\/cmd-utils\/as_gcc \$(c_flags) -c -o \$@ \$< >\$@\.xmlcmd ; \$(CC) \$(c_flags) -c -o \$(@D)\/.tmp_\$(@F) \$</g" $KERNEL_MAKEFILE_BUILD;
if [ $? -ne 0 ]; then
	ldv_print "ERROR: Failed patch (I. stage) Makefile: \"$KERNEL_MAKEFILE_BUILD\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then ldv_print "WARNING: Can't recover Makefile.build !"; fi;
	exit 1;
fi;

sed -i -e "s/^cmd_cc_o_c = \$(CC) \$(c_flags) -c -o \$@ \$</cmd_cc_o_c = \$(LDV_HOME)\/cmd-utils\/as_gcc \$(c_flags) -c -o \$@ \$< >\$@\.xmlcmd ; \$(CC) \$(c_flags) -c -o \$@ \$</g" $KERNEL_MAKEFILE_BUILD;
if [ $? -ne 0 ]; then
	ldv_print "ERROR: Failed patch (II. stage) Makefile: \"$KERNEL_MAKEFILE_BUILD\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then ldv_print "WARNING: Can't recover Makefile.build !"; fi;
	exit 1;
fi;



ldv_print "INFO: Patch final link...";
ldv_print "DEBUG: $kernel_final_link_patch $KERNEL_MAKEFILE_DIR";
$kernel_final_link_patch $KERNEL_MAKEFILE_DIR;
if [ $? -ne 0 ]; then
	ldv_print "ERROR: Can't apply final link patch.";
	exit 1;
fi;

#echo "kernel-make-dir=$KERNEL_MAKEFILE_DIR" >> $1;
echo "status=prepared" >> $1;

