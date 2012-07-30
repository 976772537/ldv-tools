DIR=$(dirname $(readlink -f "$0"))
DIR=$DIR/../..
RULE=${RULE:-106_1a}
KERNEL_OLD=${KERNEL_OLD:-linux-3.4.4}
KERNEL_NEW=${KERNEL_NEW:-linux-2.6.31.6}
MAIN=${MAIN:-ldv_main0_sequence_infinite_withcheck_stateful}

function fill_test
{
    for i in $DIR/drivers/${RULE}/${1}/[SU]-*.c; do
        TEST=$(basename "$i")
        [[ "$TEST" == S* ]] && VERDICT=safe
        [[ "$TEST" == U* ]] && VERDICT=unsafe
        echo "driver=${RULE}--${1}.tar.bz2;origin=external;kernel=${KERNEL};model=${RULE};module=drivers/${RULE}/${1}/${TEST/.c/-test.ko};main=${MAIN};verdict=${VERDICT}"
    done
}

KERNEL=$KERNEL_OLD
fill_test test-safe-old
fill_test test-unsafe-old

KERNEL=$KERNEL_NEW
fill_test test-safe-new
fill_test test-unsafe-new