#!/bin/sh

#
# ldv.sh workdir kerneldir driver
#

GLOBAL_LOG="global.log";
XML_FILENAME_AFTER_BCE="cmd_after_bce.xml";
XML_FILENAME_AFTER_DEG="cmd_after_deg.xml";
BCE_WORK_DIRNAME="bce_tempdir";
LOG_PREFIX="ldv: ";
LOG_MIRROR_TO_CONSOLE=1;

ldv_print() {
        if [ $LOG_MIRROR_TO_CONSOLE -ne 0 ]; then echo "$LOG_PREFIX$1"; fi;
        if [ ! -f "$NEXT_WORK_DIR/$GLOBAL_LOG" ];  then
                touch $NEXT_WORK_DIR/$GLOBAL_LOG;
                if [ $? -ne 0 ]; then
                        echo "ERROR: can't create log file.";
                        exit 1;
                fi;
        fi;
        echo "$LOG_PREFIX$1" >> $NEXT_WORK_DIR/$GLOBAL_LOG;
}


REPO_PATH=`pwd`"/../";

LDV_TEMPDIR_NAME="ldv_tempdir";
DRIVERDIIR_NAME="driver";

BCE_DIR="$REPO_PATH/build-cmd-extractor";
BCE="$BCE_DIR/build-cmd-extractor.sh";

DEG_DIR="$REPO_PATH/drv-env-gen";
DEG="java -ea -jar $DEG_DIR/dist/drv-env-gen.jar";

DSCV_DIR="$REPO_PATH/dscv";
DSCV="$DSCV_DIR/dscv";

RINSTR_DIR="$REPO_PATH/rule-instrumentor";
RINSTR="$RINSTR_DIR/rule-instrumentor.pl";

if [ $# -ne 3 ]; then
	echo "USAGE: ldv.sh workdir kerneldir driver"
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

NEXT_WORK_DIR=$WORK_DIR/$LDV_TEMPDIR_NAME;
mkdir $NEXT_WORK_DIR;
if [ $? -ne 0 ]; then
        echo "Failed to create next working dir for bce: \"$3\"."
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

DRIVER_DIR=$NEXT_WORK_DIR/$DRIVERDIIR_NAME;
mkdir $DRIVER_DIR;
if [ $? -ne 0 ]; then
        ldv_print "Failed to create driver dir: \"$2\"."
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

$BCE $WORK_DIR $KERNEL_DIR $DRIVER_DIR;
if [ $? -ne 0 ]; then
        ldv_print "Cmd extractor failed."
        exit 1;
fi;
BCE_WORK_DIR=$WORK_DIR/$BCE_WORK_DIRNAME;
#
# run DEG:
#
CMD_XML=$NEXT_WORK_DIR/"cmd.xml";
CMD_XML_BCE=$BCE_WORK_DIR/"cmd.xml";

echo "$DEG $WORK_DIR $CMD_XML $CMD_XML_BCE;";
$DEG $WORK_DIR $CMD_XML $CMD_XML_BCE;
if [ $? -ne 0 ]; then
        ldv_print "Drv-env-gen failed."
        exit 1;
fi;

RULE_INSTRUMENTOR=$RINSTR LDV_RULE_DB=$4 LDV_WORK_DIR=$WORK_DIR/deg_tempdir $DSCV --cmdfile=$CMD_XML_BCE --properties=$5;
if [ $? -ne 0 ]; then
        ldv_print "DSCV failed."
        exit 1;
fi;



