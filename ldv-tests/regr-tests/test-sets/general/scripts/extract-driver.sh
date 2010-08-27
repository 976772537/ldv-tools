#!/bin/bash
function usage {
cat 1>&2 <<usage_ends
Usage:
        extract-driver.sh /dir/to/save/to prefix kernelsrc drvpath verdict
Example:
	extract-driver.sh ./drivers/verdict-unsafe/ "test-0032-verdict" /root/mutilin/ldv-tools-test/kernels/linux-2.6.31.6 drivers/scsi/libfc/fc_disc.c unsafe
  
usage_ends
exit 1;
}

RESPATH=$1
test -d $RESPATH || (echo "res path does not exists $RESPATH" && usage)
INPUTPREFIX=$2;
test -n $INPUTPREFIX || (echo "empty prefix $INPUTPREFIX" && usage)
KERNELSRC=$3
test -d $KERNELSRC || (echo "kernel src does not exists $KERNELSRC" && usage)

DRVPATH=$4
test -n $DRVPATH || (echo "empty drvpath $DRVPATH" && usage)
VERDICT=$5
test -n $VERDICT || (echo "empty verdict $VERDICT" && usage)

PREFIX="$INPUTPREFIX-$VERDICT";
if `test -e $KERNELSRC/$DRVPATH`; 
then
	DRVDIR=`dirname $KERNELSRC/$DRVPATH`;
	DRVRES=`echo $DRVPATH | sed 's/\//--/g'`;
	FINALPATH="$RESPATH/$PREFIX-$DRVRES";
	mkdir -p $FINALPATH;
	cp $KERNELSRC/$DRVPATH $FINALPATH;
	
	DRVOBJ=`basename $DRVPATH | sed 's/\.c/\.o/g'`;
	echo "obj-m := $DRVOBJ" > $FINALPATH/Makefile;
	
	if `ls $DRVDIR/*.h > /dev/null 2>&1`;
	then
		cp $DRVDIR/*.h $FINALPATH;
	fi
	if `echo $DRVPATH | grep -q -e 'dvb-usb'` || `echo $DRVPATH | grep -q -e 'dvb-ttusb'` || `echo $DRVPATH | grep -q -e 'au0828'` ||  `echo $DRVPATH | grep -q -e 'drivers/media/video'`; then
		echo "apply DVB USB driver hack";
		#cp $KERNELSRC/drivers/media/dvb/dvb-core/*.h $KERNELSRC/drivers/media/dvb/frontends/*.h $KERNELSRC/drivers/media/common/tuners/*.h $FINALPATH
		echo "EXTRA_CFLAGS += -Idrivers/media/video" >>  $FINALPATH/Makefile;
		echo "EXTRA_CFLAGS += -Idrivers/media/common/tuners" >>  $FINALPATH/Makefile;
		echo "EXTRA_CFLAGS += -Idrivers/media/dvb/dvb-core" >>  $FINALPATH/Makefile;
		echo "EXTRA_CFLAGS += -Idrivers/media/dvb/frontends" >>  $FINALPATH/Makefile;

	fi
	if `echo $DRVPATH | grep -q -e 'mon_main.c'`; then
		echo "apply USB CORE driver hack";
		cp $KERNELSRC/drivers/usb/core/*.h $FINALPATH
		sed 's/\.\.\/core\/hcd\.h/hcd\.h/g' $KERNELSRC/$DRVPATH > $FINALPATH/`basename $DRVPATH`
	fi
	if `echo $DRVPATH | grep -q -e 'tty_io.c'`; then
		echo "apply TTY driver hack";
		sed 's/postcore_initcall/\/\/postcore_initcall/g' $KERNELSRC/$DRVPATH > $FINALPATH/`basename $DRVPATH`
	fi
	if `echo $DRVPATH | grep -q -e 'isapnp'`; then
		echo "apply ISAPNP driver hack";
		cp $KERNELSRC/drivers/pnp/*.h $FINALPATH
		sed 's/\.\.\/base\.h/base\.h/g' $KERNELSRC/$DRVPATH > $FINALPATH/`basename $DRVPATH`
	fi
	if `echo $DRVPATH | grep -q -e 'fusion'`; then
		echo "apply FUSION driver hack";
		mkdir $FINALPATH/lsi;
		cp $KERNELSRC/drivers/message/fusion/lsi/*.h $FINALPATH/lsi;
	fi
	if `echo $DRVPATH | grep -q -e 'nicstar.c'`; then
		echo "apply NICSTAR driver hack";
		cp $KERNELSRC/drivers/atm/nicstarmac.c $FINALPATH;
	fi
fi
