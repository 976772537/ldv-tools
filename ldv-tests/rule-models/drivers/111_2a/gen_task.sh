for NAME in `ls -d */ | xargs -l basename`; do 
echo "driver=111_2a--$NAME.tar.bz2;origin=external;kernel=linux-3.5;model=111_2a;module=undefined.ko;main=undefined;verdict=safe"
done;
