# Include this file from gentests.sh

OLD_SAFE=$DIR/test-safe-old
NEW_SAFE=$DIR/test-safe-new
OLD_UNSAFE=$DIR/test-unsafe-old
NEW_UNSAFE=$DIR/test-unsafe-new

TEMPLATE_DIR=$DIR/template

TEMPLATE_PATTERN="\/\* INSERT MODEL FUNCTION CALLS HERE \*\/"
MAKEFILE_PATTERN="\+="

function prepare_dirs
{
    local d
    for d in $OLD_SAFE $NEW_SAFE $OLD_UNSAFE $NEW_UNSAFE; do
        mkdir -p $d
        rm -rf $d/*
        cp $TEMPLATE_DIR/main.c $d
    done
}

function put_test # DIR NAME TEST
{
    local string1 string2
    sed -e "s/$TEMPLATE_PATTERN/$3/g" $TEMPLATE_DIR/template.c >$1/$2.c
    string1="$2-test-objs := main.o $2.o"
    string2="obj-m += $2-test.o"
    if [[ -f $1/Makefile ]] && grep -q "$MAKEFILE_PATTERN" $1/Makefile; then
        sed -e "s/^$/$string1\n/g" -i $1/Makefile
        echo $string2 >>$1/Makefile
    else
        echo $string1 >$1/Makefile
        echo >>$1/Makefile
        echo $string2 >>$1/Makefile
    fi
}

function old_version_test # TEST
{
    grep -q "usb_gadget_register_driver" <<<"$1"

}

function locate_test # TEST
{
    local dir name
    if old_version_test "$@"; then
        [[ $VERDICT = SAFE ]] && dir=$OLD_SAFE
        [[ $VERDICT = UNSAFE ]] && dir=$OLD_UNSAFE
    else
        [[ $VERDICT = SAFE ]] && dir=$NEW_SAFE
        [[ $VERDICT = UNSAFE ]] && dir=$NEW_UNSAFE
    fi
    name=${1//\\n/}
    name=$(grep -Eo '[a-zA-Z0-9_]+\(' <<<${name//\\t/})
    name=${name//[^a-zA-Z0-9_(]/}
    name=${name//(/-}
    name=$(sed -e 's/[A-Z][A-Z_]*//g' <<<$name)
    [[ ${#name} -gt 50 ]] && name=${name:0:25}-X${GLOBAL_INDEX}X-${name:${#name}-25:25}
    name=${name//--/-}
    ((GLOBAL_INDEX++))
    name=${name#-}
    name=${name%-}
    [[ -n $name ]] || name=empty
    [[ $VERDICT = SAFE ]] && name=S-$name
    [[ $VERDICT = UNSAFE ]] && name=U-$name
    [[ -f $dir/$name.c ]] && { name=$name-X${GLOBAL_INDEX}; ((GLOBAL_INDEX++)); }
    put_test $dir $name "$@"
}