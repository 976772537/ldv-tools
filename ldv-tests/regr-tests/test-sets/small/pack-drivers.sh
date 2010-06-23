#!/bin/bash
for i in `find . -name "test-*"`
do
	DRVDIR=$i;
	DRVARCH=`echo $DRVDIR | sed 's/\.\///g' | sed 's/\//--/g'`;
	tar cvfj $DRVARCH.tar.bz2 $DRVDIR
done
