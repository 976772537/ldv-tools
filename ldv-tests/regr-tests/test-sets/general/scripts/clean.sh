DRVPATH=.
if `test -d $1`; then
DRVPATH=$1;
fi
CURRDIR=`pwd`
cd $DRVPATH
rm Module.symvers *.ko *.o modules.order *.mod.c .*.o.cmd .tmp_*.gcno .*.ko.cmd
rm -r .tmp_versions
cd $CURRDIR
