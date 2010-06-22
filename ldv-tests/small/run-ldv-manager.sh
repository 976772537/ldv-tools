#!/bin/sh
MGR_PREFIX="LDV_KERNEL_RULES=/home/mutilin/LDV/ldv-new/kernel-rules/ LDV_DEBUG=50 LDV_GIT_REPO=git://itgdev.igroup.ispras.ru/ldv-tools.git ldv-manager tag=current drivers="
REP_PREFIX="LDVDB=ldvdb LDVUSER=ldvreports ldv-upload finished/current--X--"
REP_POSTFIX="*--X--default*.pax"
DESCFILE=desc.txt
while read line;
do
	#echo $line;
	if [ -n "$line" ]
	then
		LN=`echo $line | sed 's/.*##\(.*\)##.*/\1/g'`;
		echo Ln=$LN;
		DRVDIR=`echo $line | sed 's/\(.*\)##.*##.*/\1/g'`;
		echo Drvdir=$DRVDIR
		DRVARCH=`echo $DRVDIR | sed 's/\.\///g' | sed 's/\//--/g'`;
		echo "Packing $DRVARCH.tar.bz2"
		tar cvfj $DRVARCH.tar.bz2 $DRVDIR
		MGR_CMD=${MGR_PREFIX}${DRVARCH}.tar.bz2$LN
		echo $MGR_CMD;
		eval $MGR_CMD;		
		REP_CMD=$REP_PREFIX$DRVARCH$REP_POSTFIX
		echo $REP_CMD
		eval $REP_CMD
	fi
done < $DESCFILE

