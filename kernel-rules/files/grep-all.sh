#!/bin/bash
FILEC=$1
for (( i = 2 ; i <= $#; i++ )); do
PNUM=$i
PAR=${!PNUM} 
#echo $PAR
grep -e $PAR -q $FILEC 
if [ $? -ne 0 ]
then
exit 1
fi
done
exit 0
