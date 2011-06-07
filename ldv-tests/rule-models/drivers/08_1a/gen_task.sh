for NAME in `ls -d */ | xargs -l basename`; do 
echo "driver=08_1a--$NAME.tar.bz2;origin=external;kernel=linux-2.6.37;model=08_1a;module=undefined.ko;main=undefined;verdict=safe"
done;
