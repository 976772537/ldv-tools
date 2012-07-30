#!/bin/bash
DIR=$(dirname $(readlink -f "$0"))
FILE=${1:-$DIR/functions}
WHERE=${2:-./drivers}

GREEN="\033[32m"
RED="\033[31m"
DEFAULT="\033[0m"

echo -n "" >$DIR/noccurrences

MAXCOUNT=6

while read; do
    set -f
    ARR=($REPLY)
    case "${ARR[0]}" in
        "X") continue;;
        "??") continue;;
        *) NAME=$(tr -d "[*]" <<<"${ARR[-1]}")
    esac
    set +f
    FOUND=false
    COUNT=0
    for i in $(find $WHERE -name "*.c"); do
        RESULT=$(grep -C 3 -n "$NAME" $i)
        if [[ -n "$RESULT" ]]; then
            FOUND=true
            [[ "$COUNT" -eq 0 ]] && echo -e $GREEN"$NAME"$DEFAULT:
            echo @
            echo "$i":
            echo -e "$RESULT"
            ((COUNT++))
            [[ "$COUNT" -gt "$MAXCOUNT" ]] && { echo; break; }
        fi
    done
    if [[ ! $FOUND ]]; then
        echo -e $RED"$NAME"$DEFAULT
        echo
    fi
    [[ "$COUNT" -gt "$MAXCOUNT" ]] && COUNT=">${MAXCOUNT}"
    [[ $FOUND ]] && echo -e "${REPLY}\t${COUNT}" >>$DIR/noccurrences
done <$FILE
