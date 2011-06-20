for NAME in `ls -d */ | xargs -l basename`; do 
echo "driver=43_1a--$NAME.tar.bz2;origin=external;kernel=linux-2.6.37;model=43_1a;module=undefined.ko;main=undefined;verdict=safe"
done;
