for i in `ls */*.c`; do 
#echo $i;
NAME=`basename $i .c`;
#echo $NAME;
echo "driver=39_7--test-$NAME.tar.bz2;origin=external;kernel=linux-2.6.37;model=39_7;module=drivers/39_7/test-$NAME/$NAME.ko;main=ldv_main0_sequence_infinite_withcheck_stateful;verdict=unsafe"
done;
