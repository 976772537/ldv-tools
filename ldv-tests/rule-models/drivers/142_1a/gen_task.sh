for NAME in `ls -d */ | xargs -l basename`; do 
echo "driver=142_1a--$NAME.tar.bz2;origin=external;kernel=linux-3.5;model=142_1a;module=undefined.ko;main=undefined;verdict=safe"
done;
