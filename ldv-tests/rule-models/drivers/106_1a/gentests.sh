#!/bin/bash
DIR=$(dirname $(readlink -f "$0"))

. automaton.sh

# We use all simple cyclic paths (including the empty one) containing starting vertex as 'SAFE' tests
# We generate 'UNSAFE' test(s) for every vertex except the starting one (to test ldv_check_final_state)
# We also generate 'UNSAFE' test(s) for every disallowed model function call from every state
# search_calls replicates tests for every pointcut
# cycle_calls just cycles through possible pointcuts (generating much fewer test as a result)

declare -a VISITED_VERTICES
declare -A VISITED_EDGES
declare -a _PATH
declare -a TEST

function edge_in_path # edge (f-t)
{
    local from v
    from=$START
    for v in ${_PATH[@]}; do
        [[ ${EDGES[$from-$v]} = ${EDGES[$1]} ]] && return
        from=$v
    done
    false
}

function push # array
{
    eval "$1=(\${$1[@]} $2)"
}

function pop # array
{
    eval "unset $1[\${#$1[@]}-1]"
}

function peek # array
{
    eval echo -n "\${$1[\${#$1[@]}-1]}"
}

function print_test
{
    local c
    echo -n $VERDICT:
    for c in ${TEST[@]}; do
        echo -n "$c "
    done
    echo
}

function search_calls # calls
{
    local c curr last_ifs
    [[ ${#@} = 0 ]] && { print_test; return; }
    curr=$1
    shift
    last_ifs=$IFS
    IFS=';'
    for c in ${CALLS[$curr]}; do
        push TEST $c
        search_calls $@
        pop TEST
    done
    IFS=$last_ifs
}

function cycle_calls # calls
{
    local c curr buf last_ifs
    declare -a ARRAY
    [[ ${#@} = 0 ]] && { print_test; return; }
    curr=$1
    shift
    last_ifs=$IFS
    IFS=';'
    for c in ${CALLS[$curr]}; do
        push ARRAY $c
    done
    IFS=$last_ifs
    last=$(peek ARRAY)
    pop ARRAY
    ARRAY=($last $ARRAY)
    buf=${ARRAY[@]}
    buf=${buf//\ /;}
    CALLS[$curr]=$buf
    push TEST $last
    cycle_calls $@
    pop TEST
}

function print_path
{
    local from v
    from=$START
    for v in ${_PATH[@]}; do
        echo -n "${EDGES[$from-$v]} "
        from=$v
    done
}

function print_tests # verdict
{
    VERDICT=$1
    cycle_calls $(print_path)
    # search_calls $(print_path)
}

function make_safe_tests
{
    print_tests SAFE
}

function print_for_disallowed_calls
{
    local last v c
    declare -A calls
    for c in ${!CALLS[@]}; do
        calls[$c]=y # save all possible calls
    done
    [[ -n $_PATH ]] && last=$(peek _PATH) || last=$START
    for v in ${!VERTICES[@]}; do
        [[ -n ${EDGES[$last-$v]} ]] && unset calls[${EDGES[$last-$v]}] # exclude allowed calls
    done
    for c in ${!calls[@]}; do # print tests for disallowed calls
        VERDICT=UNSAFE
        cycle_calls $(print_path) $c
        # search_calls $(print_path) $c
    done
}

function print_unsafe_tests # print tests for the reached state
{
    print_tests UNSAFE # print the tests reaching the state
    print_for_disallowed_calls
}

function make_unsafe_tests_once
{
    local last
    last=$(peek _PATH)
    [[ -z ${VISITED_VERTICES[$last]} ]] && { print_unsafe_tests; VISITED_VERTICES[$last]=y; }
}

function traverse # curr_vert
{
    local v
    [[ $1 -eq $START ]] && { make_safe_tests; [[ -z ${_PATH[@]} ]] || return; } || make_unsafe_tests_once
    for v in ${!VERTICES[@]}; do
        [[ $v = $1 ]] || edge_in_path $1-$v && continue
        push _PATH $v
        [[ -z ${EDGES[$1-$v]} ]] && { pop _PATH; continue; }
        traverse $v
        pop _PATH
    done
}

traverse $START
print_for_disallowed_calls