for i in `cat drvdirs.txt`; do
echo "driver=$i;origin=kernel;kernel=linux-2.6.32.15.tar.bz2;model=BZ_1;"
echo "driver=$i;origin=kernel;kernel=linux-2.6.32.15.tar.bz2;model=BZ_2;"
echo "driver=$i;origin=kernel;kernel=linux-2.6.34.tar.bz2;model=BZ_1;"
echo "driver=$i;origin=kernel;kernel=linux-2.6.34.tar.bz2;model=BZ_2;"
done
