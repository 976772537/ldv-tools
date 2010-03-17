#!/bin/sh

GLOBAL_LOG="global.log";
KERNEL_COMPILE_LOG_FILENAME="ckc.log";
TRACE_FILENAME="build_trace";
XML_FILENAME="cmd.xml";
LOG_PREFIX="build-cmd-extractor: ";
LOG_MIRROR_TO_CONSOLE=1;
XML_CREATOR="../cmd-utils/as_gcc"

bce_print() {
	if [ $LOG_MIRROR_TO_CONSOLE -ne 0 ]; then echo "$LOG_PREFIX$1"; fi;
        if [ ! -f "$WORK_DIR/$GLOBAL_LOG" ];  then
                touch $WORK_DIR/$GLOBAL_LOG;
                if [ $? -ne 0 ]; then 
			echo "ERROR: can't create log file.";
			exit 1; 
		fi;
        fi;
        echo "$LOG_PREFIX$1" >> $WORK_DIR/$GLOBAL_LOG;
}

if [ $# -ne 3 -a $# -ne 4 ]; then
	echo "USAGE: build-cmd-extractor workdir kernel_src_dir driver_dir <xml_file>";
	exit 1;
fi;
WORK_DIR=`readlink -f $1`;
if [ $? -ne 0 ]; then
	echo "Failed to read abs-path for working dir: \"$1\"."
	exit 1;
fi;
if [ ! -d "$WORK_DIR" ]; then
	echo "Working directory does not exists: \"$WORK_DIR\".";
	exit 1;
fi;
NEXT_BASE_DIR=$WORK_DIR/"deg_tempdir";
mkdir $NEXT_BASE_DIR;
if [ $? -ne 0 ]; then
	echo "Failed to create next tempdir: \"$NEXT_BASE_DIR\".";
	exit 1;
fi;
NEXT_DIRVER_DIR=$NEXT_BASE_DIR/"driver";
WORK_DIR=$WORK_DIR"/bce_tempdir";
mkdir $WORK_DIR;
if [ $? -ne 0 ]; then
	echo "Failed to create bce tempdir: \"$WORK_DIR\".";
	exit 1;
fi;
KERNEL_DIR=`readlink -f $2`;
if [ $? -ne 0 ]; then
	bce_print "Failed to read abs-path for kernel dir: \"$2\"."
	exit 1;
fi;
if [ ! -d "$KERNEL_DIR" ]; then
	bce_print "Kernel directory does not exists: \"$KERNEL_DIR\".";
	exit 1;
fi;
DRIVER_DIR=`readlink -f $3`;
if [ $? -ne 0 ]; then
	bce_print "Failed to read abs-path for driver dir: \"$3\"."
	exit 1;
fi;
if [ ! -d "$DRIVER_DIR" ]; then
	bce_print "Driver directory does not exists: \"$DRIVER_DIR\".";
	exit 1;
fi;
if [ $# -eq 4 ]; then
	CMD_XML_FILE=`readlink -f $4`;
	if [ $? -ne 0 ]; then
		bce_print "Failed to read abs path for: \"$4\"."
		exit 1;
	fi;
	touch $CMD_XML_FILE;
	if [ $? -ne 0 ]; then
		bce_print "Failed to create empty XML file: \"$4\"."
		exit 1;
	fi;
fi;

#
# copy driver sources for next instrument
#
cp -r $DRIVER_DIR $NEXT_DIRVER_DIR;
if [ $? -ne 0 ]; then
	bce_print "Failed to copy driver sources for next instrument."
	exit 1;
fi;

#
# create directory for driver build
#
DRIVER_TRACE_DIR=$WORK_DIR"/driver";
mkdir $DRIVER_TRACE_DIR;
if [ $? -ne 0 ]; then
	bce_print "Failed to create dir for driver in tempdir: \"$DRIVER_TRACE_DIR\".";
	exit 1;
fi;
#
# copy driver sources to tempdir 
#
cp -r $DRIVER_DIR/* $DRIVER_TRACE_DIR/
if [ $? -ne 0 ]; then
	bce_print "Failed to copy driver sources.";
	exit 1;
fi;


#
# try to find "scripts/Makefile.build" in kernel source directory
# 
KERNEL_MAKEFILE_BUILD=$KERNEL_DIR"/scripts/Makefile.build";
if [ ! -f "$KERNEL_MAKEFILE_BUILD" ]; then
	bce_print "Can't find kernel makefile: \"$KERNEL_MAKEFILE_BUILD\".";
	exit 1;
fi;

#
# copy Makefile for last recovery...
#
KERNEL_BACKUP_MAKEFILE_BUILD=$KERNEL_DIR"/scripts/Makefile.build.bcebackup";
cp $KERNEL_MAKEFILE_BUILD $KERNEL_BACKUP_MAKEFILE_BUILD;
if [ $? -ne 0 ]; then
	bce_print "Failed to copy Makefile: \"$KERNEL_MAKEFILE_BUILD\" to \"$KERNEL_BACKUP_MAKEFILE_BUILD\".";
	exit 1;
fi;
#
# test if a FILE exists and write permission is granted or not
#
if [ ! -w "$KERNEL_MAKEFILE_BUILD" ]; then
	bce_print "Kernel Makefile.build: \"$KERNEL_MAKEFILE_BUILD\" -  not writable.";
	exit 1;
fi;

#*****************************************************************************************
# hack to export trace in kernel ./scripts/Makefile.build:
#
# I. replace string
# cmd_cc_o_c = $(CC) $(c_flags) -c -o $(@D)/.tmp_$(@F) $<
# with
# cmd_cc_o_c = echo "CFLAGS_FOR_FILE = "$@ >> $(BUILDFILE); echo "CFLAGS = "'$(c_flags)' >> $(BUILDFILE); $(CC) $(c_flags) -c -o $(@D)/.tmp_$(@F) $<
#
#
# II. replace string
#                         cat $m;, echo kernel/$m;))
# with
#                         cat $m;, echo "MODULE = $m" >> $(BUILDFILE); echo kernel/$m;))
#
#
# III. replace string
# cmd_link_multi-y = $(LD) $(ld_flags) -r -o $@ $(link_multi_deps) $(cmd_secanalysis)
# with
# cmd_link_multi-y = echo "LDFLAGS = $(ld_flags)" >> $(BUILDFILE); echo "DEPS = $(link_multi_deps)">> $(BUILDFILE);$(LD) $(ld_flags) -r -o $@ $(link_multi_deps) $(cmd_secanalysis)
#
#***************************************************************************************
# I.
sed -i -e "s/^cmd_cc_o_c = \$(CC) \$(c_flags) -c -o \$(@D)\/\.tmp_\$(@F) \$</cmd_cc_o_c = echo \"CFLAGS_FOR_FILE = \"\$@\" CFLAGS = \"'\$(c_flags)' >> \$(BUILDFILE); \$(CC) \$(c_flags) -c -o \$(@D)\/.tmp_\$(@F) \$</g" $KERNEL_MAKEFILE_BUILD;
if [ $? -ne 0 ]; then
	bce_print "Failed patch (I. stage) Makefile: \"$KERNEL_MAKEFILE_BUILD\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then bce_print "ATTENSION: Can't recover Makefile.build !"; fi;
	exit 1;
fi;
# II.
sed -i -e "s/\scat \$m;, echo kernel\/\$m;))/cat \$m;, echo \"MODULE = \$m\" >> \$(BUILDFILE); echo kernel\/\$m;))/g" $KERNEL_MAKEFILE_BUILD;
if [ $? -ne 0 ]; then
	bce_print "Failed patch (II. stage) Makefile: \"$KERNEL_MAKEFILE_BUILD\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then bce_print "ATTENSION: Can't recover Makefile.build !"; fi;
	exit 1;
fi;
# III.
sed -i -e "s/^cmd_link_multi-y = \$(LD) \$(ld_flags) -r -o \$@ \$(link_multi_deps) \$(cmd_secanalysis)/cmd_link_multi-y = echo \"LDFLAGS_FOR_FILE = \$@ LDFLAGS = -r -o \$(ld_flags) DEPS = \$(link_multi_deps)\" >> \$(BUILDFILE); \$(LD) \$(ld_flags) -r -o \$@ \$(link_multi_deps) \$(cmd_secanalysis)/g" $KERNEL_MAKEFILE_BUILD;
if [ $? -ne 0 ]; then
	bce_print "Failed patch (III. stage) Makefile: \"$KERNEL_MAKEFILE_BUILD\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then bce_print "ATTENSION: Can't recover Makefile.build !"; fi;
	exit 1;
fi;
#
# Ok, and now try to start make for driver (driver must be prepared for make)
#
TRACE_FILE="$WORK_DIR/$TRACE_FILENAME";
KERNEL_COMPILE_LOG="$WORK_DIR/$KERNEL_COMPILE_LOG_FILENAME";	
cd $KERNEL_DIR;
if [ $? -ne 0 ]; then
	bce_print "Failed change dir to: \"$KERNEL_DIR\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then bce_print "ATTENSION: Can't recover Makefile.build !"; fi;
	exit 1;
fi;
make $DRIVER_TRACE_DIR/ BUILDFILE=$TRACE_FILE > $KERNEL_COMPILE_LOG 2>&1;
if [ $? -ne 0 ]; then
	bce_print "Error during driver compile. See compile log for more details: \"$KERNEL_COMPILE_LOG\".";
	cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
	if [ $? -ne 0 ]; then bce_print "ATTENSION: Can't recover Makefile.build !"; fi;
	exit 1;
fi;
#
# !!! recover Makefile in all cases !!!
#
cp $KERNEL_BACKUP_MAKEFILE_BUILD $KERNEL_MAKEFILE_BUILD;
if [ $? -ne 0 ]; then 
	bce_print "ATTENSION: Can't recover Makefile.build !"; 
	exit 1; 
fi;

#
# test - trace file created or not...
#
if [ ! -f "$TRACE_FILE" ]; then
	bce_print "Can't find build trace file: \"$TRACE_FILE\" .";
	exit 1;
fi;

#
# Is it single-driver ?
#
# TODO: 1. find MODULE - test if LDFLAGS_FOR_FILE not exists for this module then add it
#
IS_MULTIPLE=`grep '^LDFLAGS_FOR_FILE' $TRACE_FILE`;
# driver single - then fix trace file - add LDFLAGS_FOR_FILE
if [ ! -n "$IS_MULTIPLE" ]; then
	cat $TRACE_FILE | while read line; do
		MODULE_TAG=`echo $line | grep '^MODULE\ =\ '`;
#		CUR_MODULE=`echo $MODULE_TAG | sed 's/^MODULE = //' | sed 's/\.ko$/.o/'`;
		CUR_MODULE=`echo $MODULE_TAG | sed 's/^MODULE = //'`;
		if [ -n "$CUR_MODULE" ]; then		
			echo "LDFLAGS_FOR_FILE = $CUR_MODULE LDFLAGS = -r -o DEPS = "`echo $CUR_MODULE | sed 's/\.ko$/.o/'` >> $TRACE_FILE;
		fi;
	done;
fi;

#
# and now create xml file from build-trace-file
#
if [ -n "$CMD_XML_FILE" ]; then
	CMD_XML=$CMD_XML_FILE;
else
	CMD_XML="$WORK_DIR/$XML_FILENAME";
fi;

echo "<?xml version=\"1.0\"?>" > $CMD_XML;
echo "<cmdstream>" >> $CMD_XML;

echo -e "\t<basedir>$NEXT_BASE_DIR</basedir>" >> $CMD_XML;
k=1;

#  xml.replace("&", "&amp;"); 
#  xml.replace("<", "&lt;"); 
#  xml.replace(">", "&gt;"); 
#  xml.replace(" ", "&apos;"); 
#  xml.replace("\"", "&quot;"); 

cat $TRACE_FILE | while read line; do
	CC_FILE_ABS=`echo $line | grep ^CFLAGS_FOR_FILE | sed 's/^CFLAGS_FOR_FILE = //' | sed 's/ CFLAGS = .*//'`;
	LD_FILE_ABS=`echo $line | grep ^LDFLAGS_FOR_FILE | sed 's/^LDFLAGS_FOR_FILE = //' | sed 's/ LDFLAGS = .*//'`;
	if [ "$CC_FILE_ABS" ]; then
#		SQUARED_WORK_DIR=`echo $WORK_DIR | sed 's/\//\\\\\\//g'`"\\/";
#		XML_CWD=`dirname $CC_FILE_ABS | sed "s/$SQUARED_WORK_DIR//"`;
#		SQUARED_WOR_DIR_EXT="$SQUARED_WORK_DIR$XML_CWD\\/";
#		FILE_O=`echo $CC_FILE_ABS | sed "s/$SQUARED_WOR_DIR_EXT//"`;
#		FILE_C=`echo $FILE_O | sed 's/\.o$/\.c/'`;
		echo -e "\t<cc id=\"$k\">" >> $CMD_XML;
		echo -e "\t\t<cwd>$KERNEL_DIR</cwd>" >> $CMD_XML;
		echo -e "\t\t<in>"`echo $CC_FILE_ABS | sed 's/\.o/.c/' | sed 's/bce_tempdir/deg_tempdir/'`"</in>" >> $CMD_XML;
		for j in `echo $line | sed 's/^CFLAGS_FOR_FILE = .* CFLAGS = //'`; do
			echo -e "\t\t<opt>$j</opt>" >> $CMD_XML;
		done;
		echo -e "\t\t<out>"`echo $CC_FILE_ABS | sed 's/bce_tempdir/deg_tempdir/'`"</out>" >> $CMD_XML;
		echo -e "\t</cc>" >> $CMD_XML; 
		let k=$k+1;
	elif [ "$LD_FILE_ABS" ]; then
		LD_FLAGS=`echo $line | sed 's/^LDFLAGS_FOR_FILE = .* LDFLAGS = //' | sed 's/DEPS = .*$//'`;
		echo -e "\t<ld id=\"$k\">" >> $CMD_XML;
		echo -e "\t\t<cwd>$KERNEL_DIR</cwd>" >> $CMD_XML;
		for j in `echo $line | sed 's/^LDFLAGS_FOR_FILE = .* DEPS = //'`; do
			echo -e "\t\t<in>"`echo $j | sed 's/bce_tempdir/deg_tempdir/'`"</in>" >> $CMD_XML;
		done;
		for j in `echo $line | sed 's/^LDFLAGS_FOR_FILE = .* LDFLAGS = //' | sed 's/DEPS = .*$//'`; do
			echo -e "\t\t<opt>$j</opt>" >> $CMD_XML;
		done;
		echo -e "\t\t<out>"`echo $LD_FILE_ABS | sed 's/bce_tempdir/deg_tempdir/'`"</out>" >> $CMD_XML;
		echo -e "\t</ld>" >> $CMD_XML; 
		let k=$k+1;
	fi;
done;
echo -e "</cmdstream>" >> $CMD_XML;
