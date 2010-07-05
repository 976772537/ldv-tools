#!/bin/sh
DESCFILE=desc.txt
while read line;
do
	#echo $line;
	if [ -n "$line" ]
	then
		LN=`echo $line | sed 's/.*##\(.*\)##.*/\1/g'`;
		#echo Ln=$LN;
		DRVDIR=`echo $line | sed 's/\(.*\)##.*##.*/\1/g'`;
		#echo Drvdir=$DRVDIR
		DRVARCH=`echo $DRVDIR | sed 's/\.\///g' | sed 's/\//--/g'`;
		#echo "Packing $DRVARCH.tar.bz2"
		echo "driver=$DRVARCH.tar.bz2;origin=external;kernel=mykernel-1-2.6.32.15.tar.bz2;model="
	fi
done < $DESCFILE

