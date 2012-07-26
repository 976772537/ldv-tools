#!/bin/bash
DIR=$(dirname $(readlink -f "$0"))

. automaton.sh

# Here we use an automaton and dfsm traversing algorithm from UniTESK

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
    search_calls $(print_path)
}

function make_safe_tests
{
    print_tests SAFE
}

function print_unsafe_tests # print tests for the reached state
{
    local last v c
    declare -A calls
    print_tests UNSAFE # print the tests reaching the state
    for c in ${!CALLS[@]}; do
        calls[$c]=y # save all possible calls
    done
    last=$(peek _PATH)
    for v in ${!VERTICES[@]}; do
        [[ -n ${EDGES[$last-$v]} ]] && unset calls[${EDGES[$last-$v]}] # exclude allowed calls
    done
    for c in ${!calls[@]}; do # print tests for disallowed calls
        VERDICT=UNSAFE
        search_calls $(print_path) $c
    done
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