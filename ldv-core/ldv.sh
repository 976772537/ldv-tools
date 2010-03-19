#!/bin/sh

#
# ldv.sh workdir kerneldir driver
#

GLOBAL_LOG="global.log";
XML_FILENAME="cmd.xml";
LOG_PREFIX="ldv: ";
LOG_MIRROR_TO_CONSOLE=1;

ldv_print() {
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


#REPO_PATH="/home/iceberg/ldv-tools";
REPO_PATH=`pwd`"/../";

BCE_DIR="$REPO_PATH/build-cmd-extractor";
BCE="$BCE_DIR/build-cmd-extractor.sh";

DEG_DIR="$REPO_PATH/drv-env-gen";
DEG="java -ea -jar $DEG_DIR/dist/drv-env-gen.jar";

DSCV_DIR="$REPO_PATH/dscv";
DSCV="$DSCV_DIR/dscv";


if [ $# -ne 5 ]; then
	echo "USAGE: ldv.sh workdir kerneldir driver ldv_rule_db ruleslist"
	exit 1;
fi;

GLOBAL_WORK_DIR=`readlink -f $1`;
if [ $? -ne 0 ]; then
        echo "Failed to read abs-path for working dir: \"$1\"."
        exit 1;
fi;
if [ ! -d "$GLOBAL_WORK_DIR" ]; then
        echo "Working directory does not exists: \"$GLOBAL_WORK_DIR\".";
        exit 1;
fi;

WORK_DIR=$GLOBAL_WORK_DIR"/ldv_tempdir";
mkdir $WORK_DIR;
if [ $? -ne 0 ]; then
        echo "Failed to create ldv tempdir: \"$WORK_DIR\".";
        exit 1;
fi;

KERNEL_DIR=`readlink -f $2`;
if [ $? -ne 0 ]; then
        ldv_print "Failed to read abs-path for kernel dir: \"$2\"."
        exit 1;
fi;
if [ ! -d "$KERNEL_DIR" ]; then
        ldv_print "Kernel directory does not exists: \"$KERNEL_DIR\".";
        exit 1;
fi;

DRIVER_FILE=`readlink -f $3`;
if [ $? -ne 0 ]; then
        ldv_print "Failed to read abs-path for driver: \"$3\"."
        exit 1;
fi;
if [ ! -f "$DRIVER_FILE" ]; then
        ldv_print "File with driver does not exists: \"$DRIVER_FILE\".";
        exit 1;
fi;

DRIVER_DIR="$WORK_DIR/driver";
mkdir $DRIVER_DIR;
if [ $? -ne 0 ]; then
        ldv_print "Failed to crate dir for driver: \"$3\"."
        exit 1;
fi;

#
# test format for driver file and unpack driver
#
case `file -b $DRIVER_FILE --mime-type` in
	application/x-bzip2)
		tar xvjpf $DRIVER_FILE -C $DRIVER_DIR;; 
	application/x-gzip)
		tar xvzpf $DRIVER_FILE -C $DRIVER_DIR;; 
	*)
		ldv_print "Unknown driver file type.";
		exit 1;;
esac
if [ $? -ne 0 ]; then
        ldv_print "Failed to unpached archive: \"$DRIVER_FILE\"."
        exit 1;
fi;
 
#
# TODO: find Makefile and other - to build-extractor (test that driver have correct Makefile or Kbuild)
# 
XML_STAGE_I="$WORK_DIR/cmd.xml";
$BCE $GLOBAL_WORK_DIR $KERNEL_DIR $DRIVER_DIR $XML_STAGE_I;
if [ $? -ne 0 ]; then
        ldv_print "Cmd extractor failed."
        exit 1;
fi;

#
# run DEG:
#
CMD_XML="$GLOBAL_WORK_DIR/cmd.xml";
cp $XML_STAGE_I $CMD_XML;
if [ $? -ne 0 ]; then
        ldv_print "Can not copy xml after bce."
        exit 1;
fi;

$DEG $GLOBAL_WORK_DIR $XML_STAGE_I $CMD_XML;
if [ $? -ne 0 ]; then
        ldv_print "Drv-env-gen failed."
        exit 1;
fi;
echo "LDV_RULE_DB=$4 LDV_WORK_DIR=$GLOBAL_WORK_DIR/dscv_tempdir $DSCV --cmdfile=$CMD_XML --properties=$5;";
LDV_RULE_DB=$4 LDV_WORK_DIR=$GLOBAL_WORK_DIR/dscv_tempdir $DSCV --cmdfile=$CMD_XML --properties=$5;
if [ $? -ne 0 ]; then
        ldv_print "DSCV failed."
        exit 1;
fi;
#     $ LDV_RULE_DB=/path/to/rule_db LDV_WORK_DIR=/path/to/workdir \
#             dscv --cmdfile=commands.xml --rules=0032a,0039



