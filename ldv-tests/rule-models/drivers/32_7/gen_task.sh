for NAME in `ls -d */ | xargs -l basename`; do 
echo "driver=32_7--$NAME.tar.bz2;origin=external;kernel=linux-3.5;model=32_7;module=undefined.ko;main=undefined;verdict=safe"
done;
