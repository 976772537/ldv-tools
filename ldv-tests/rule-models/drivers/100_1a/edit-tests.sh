#!/bin/bash
DIR=$(dirname $(readlink -f "$0"))
BEFORE_PATTERN="static struct.*"

for i in $(cat $DIR/cutpoints); do
	cd test-$i
	for j in S U; do
		sed -e "1,/^$BEFORE_PATTERN/ {/^$BEFORE_PATTERN/i\
struct tty_struct *dummy_source_tty;
}" -e "s/kmalloc(.*)/tty_kref_get(dummy_source_tty)/g" $j-$i.c >$j-$i-tty_kref_get.c

		sed -e "1,/^$BEFORE_PATTERN/ {/^$BEFORE_PATTERN/i\
struct tty_port *dummy_source_tty_port;
}" -e "s/kmalloc(.*)/tty_port_tty_get(dummy_source_tty_port)/g" $j-$i.c >$j-$i-tty_port_tty_get.c

		sed -e "s/kmalloc(.*)/get_current_tty()/g" $j-$i.c >$j-$i-get_current_tty.c
	done
	cd ..
done
