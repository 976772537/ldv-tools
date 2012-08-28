#!/bin/bash
DIR=$(dirname $(readlink -f "$0"))

for i in $(cat $DIR/cutpoints); do
	mv test-$i/U-$i.c test-$i/S-$i-2.c
done
