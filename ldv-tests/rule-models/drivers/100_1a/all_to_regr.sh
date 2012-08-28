DIR=$(dirname $(readlink -f "$0"))
DIR=$DIR/../..
RULE=${RULE:-100_1a}
KERNEL=${KERNEL:-linux-3.5}
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

for i in $DIR/drivers/${RULE}/test-*; do
    [[ -d "$i" ]] || continue
    fill_test $(basename "$i")
done