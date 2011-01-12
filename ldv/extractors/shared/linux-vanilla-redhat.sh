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
kernel_final_link_patch="$LDV_HOME/ldv/extractors/linux-vanilla/fix_bigobj.pl -k ";
ldv_print "NORMAL: Kernel version is: $k_kernelversion";

#
# if options not set =>
#   i am set default allmodconfig
#
if [ -n "$LDVGIT_CONFIG_CMD" ]; then
        KERNEL_CONFIG_OPTIONS=$LDVGIT_CONFIG_CMD;
else
	if [ ! -n "$DSCR_OPTIONS" ]; then 
		KERNEL_CONFIG_OPTIONS="make allyesconfig"; 
	else 
		KERNEL_CONFIG_OPTIONS="make $DSCR_OPTIONS"; 
	fi;
fi;
ldv_print "NORMAL: Kernel configure command is: \"$KERNEL_CONFIG_OPTIONS\"";
$KERNEL_CONFIG_OPTIONS;
if [ $? -ne 0 ]; then
        ldv_print "ERROR: command \"$KERNEL_CONFIG_OPTIONS\" failed."
        exit 1;
fi;
make init;
if [ $? -ne 0 ]; then
        ldv_print "ERROR: make init failed."
        exit 1;
fi;
#
# try to find "scripts/Makefile.build" in kernel source directory
# 
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
# test if a FILE exists and write permission is granted or not
#
if [ ! -w "$KERNEL_MAKEFILE_BUILD" ]; then
	ldv_print "ERROR: Kernel Makefile.build: \"$KERNEL_MAKEFILE_BUILD\" -  not writable.";
	exit 1;
fi;

# I.
sed -i -e "s/^cmd_cc_o_c = \$(CC) \$(c_flags) -c -o \$(@D)\/\.tmp_\$(@F) \$</cmd_cc_o_c = $XGCC \`readlink -f \$<\` \$(c_flags) -c -o \`readlink -f \$(@D)\/\$(@F)\` >> \`if \[ -n \"\$(BUILDFILE)\" \]; then echo \$(BUILDFILE); else echo \/dev\/null; fi\`; \$(CC) \$(c_flags) -c -o \$(@D)\/.tmp_\$(@F) \$</g" $KERNEL_MAKEFILE_BUILD;
if [ $? -ne 0 ]; then
	ldv_print "ERROR: Failed patch (I. stage) Makefile: \"$KERNEL_MAKEFILE_BUILD\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then ldv_print "WARNING: Can't recover Makefile.build !"; fi;
	exit 1;
fi;
# II.
#sed -i -e "s/^cmd_link_multi-m = \$(cmd_link_multi-y)/cmd_link_multi-m = $XGCC \$(ld_flags) \`for i in \$(link_multi_deps); do echo \\\\\`readlink -f \$\$i\\\\\`; done | xargs\` -r -o \`readlink -f \$@\` >> \`if \[ -n \"\$(BUILDFILE)\" \]; then echo \$(BUILDFILE); else echo \/dev\/null; fi\`; \$(cmd_link_multi-y)/g" $KERNEL_MAKEFILE_BUILD;
#if [ $? -ne 0 ]; then
#	ldv_print "ERROR: Failed patch (III. stage) Makefile: \"$KERNEL_MAKEFILE_BUILD\".";
#	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
#	if [ $? -ne 0 ]; then ldv_print "WARNING: Can't recover Makefile.build !"; fi;
#	exit 1;
#fi;



sed -i -e "s/^cmd_link_multi-y = \$(LD) \$(ld_flags) -r -o \$@ \$(link_multi_deps) \$(cmd_secanalysis)/cmd_link_multi-y = $XGCC \$(ld_flags) \`for i in \$(link_multi_deps); do echo \\\\\`readlink -f \$\$i\\\\\`; done | xargs\` -r -o \`readlink -f \$@\` >> \`if \[ -n \"\$(BUILDFILE)\" \]; then echo \$(BUILDFILE); else echo \/dev\/null; fi\`; \$(LD) \$(ld_flags) -r -o \$@ \$(link_multi_deps) \$(cmd_secanalysis)/g" $KERNEL_MAKEFILE_BUILD;
if [ $? -ne 0 ]; then
	ldv_print "ERROR: Failed patch (III. stage) Makefile: \"$KERNEL_MAKEFILE_BUILD\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then ldv_print "WARNING: Can't recover Makefile.build !"; fi;
	exit 1;
fi;
# III.
#
# try to find "scripts/Makefile.modpost" in kernel source directory
# 
KERNEL_MAKEFILE_MODPOST=$KERNEL_MAKEFILE_DIR"/scripts/Makefile.modpost";
if [ ! -f "$KERNEL_MAKEFILE_MODPOST" ]; then
	ldv_print "ERROR: Can't find kernel makefile for modules: \"$KERNEL_MAKEFILE_MODPOST\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then ldv_print "WARNING: Can't recover Makefile.build !"; fi;
	exit 1;
fi;
#
# Create backup for ./scripts/Makefile.modpost
#
KERNEL_BACKUP_MAKEFILE_MODPOST=$KERNEL_MAKEFILE_DIR"/scripts/Makefile.modpost.bcebackup";
cp $KERNEL_MAKEFILE_MODPOST $KERNEL_BACKUP_MAKEFILE_MODPOST;
if [ $? -ne 0 ]; then
	ldv_print "ERROR: Failed to copy Makefile.modpost from: \"$KERNEL_MAKEFILE_MODPOST\" to \"$KERNEL_BACKUP_MAKEFILE_MODPOST\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then ldv_print "WARNING: Can't recover Makefile.build !"; fi;
	exit 1;
fi;
#
# test if a FILE exists and write permission is granted or not
#
if [ ! -w "$KERNEL_MAKEFILE_MODPOST" ]; then
	ldv_print "ERROR: Kernel Makefile.modpost: \"$KERNEL_MAKEFILE_MODPOST\" -  not writable.";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then ldv_print "WARNING: Can't recover Makefile.build !"; fi;
	exit 1;
fi;
#
# patch it...
#
sed -i -e "s/\\(^\s\+\\(-o \$@ \\)\?\$(filter-out FORCE,\$^)\\)/\\1; BUILDFILE=\$(BUILDFILE) $BCE_XGCC \`readlink -f \$@\`/g" $KERNEL_MAKEFILE_MODPOST;
if [ $? -ne 0 ]; then
	ldv_print "ERROR: Failed patch (I. stage) Makefile: \"$KERNEL_MAKEFILE_BUILD\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then ldv_print "WARNING: Can't recover Makefile.build !"; fi;
	exit 1;
fi;

ldv_print "INFO: Apply complex patch...";
ldv_print "DEBUG: $kernel_final_link_patch $KERNEL_MAKEFILE_DIR";
$kernel_final_link_patch $KERNEL_MAKEFILE_DIR;
if [ $? -ne 0 ]; then
        ldv_print "ERROR: Can't apply complex patch.";
        exit 1;
fi;


echo "kernel-make-dir=$KERNEL_MAKEFILE_DIR" >> $1;
echo "status=prepared" >> $1;

