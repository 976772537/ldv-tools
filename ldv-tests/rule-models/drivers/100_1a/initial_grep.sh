#!/bin/bash
DIR=${1:-.}
WS="[ \n\t]+"
WSS="[ \n\t\*]+"
INSIDE_PARENS="[ \n\t\*a-zA-Z0-9_,\[\]]*"
TTY_STRUCT_TAG="tty_struct"
TTY_STRUCT_P_PATTERN="struct${WS}${TTY_STRUCT_TAG}(${WS})?\*"
ID="[_a-zA-Z][_a-zA-Z0-9]*"
PATTERN="(${ID}${WS})?(${ID}${WS})?${ID}${WSS}${ID}\(${INSIDE_PARENS}${TTY_STRUCT_P_PATTERN}${INSIDE_PARENS}\)"

FILES="tty_driver.h tty_flip.h tty.h tty_ldisc.h"
SUBDIR='include/linux'

for i in $FILES; do
    FILE=$SUBDIR/$i
    BUF=$(pcregrep  -Mo "$PATTERN" $FILE)
    echo -n $BUF | sed -e 's/([^()]*)\ */\n/g'
done

