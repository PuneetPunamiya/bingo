#! /bin/bash
set  -u #-x
declare -r TEST_DIR=$(cd $(dirname "$0") && pwd)
touch $TEST_DIR/defaults.conf

source $TEST_DIR/../lib/bingo.bash

cleanup() { rm -f $TEST_DIR/defaults.conf; }
on_exit cleanup


foo.foo.foo.foo() {
    local lvl=$1
    local exit_code=$2
    log.debug "cannot go any deeper ..."
    exit $exit_code
}

foo.foo.foo() {
    local lvl=$1
    local exit_code=$2
    test $lvl -eq 0 && exit $exit_code
    (( lvl-- ))
    foo.foo.foo.foo $lvl $exit_code
}


foo.foo() {
    local lvl=$1
    local exit_code=$2
    test $lvl -eq 0 && exit $exit_code
    test $lvl -eq 0 && exit $exit_code
    (( lvl-- ))
    foo.foo.foo $lvl $exit_code
}


foo() {
    local lvl=$1
    local exit_code=$2
    test $lvl -eq 0 && exit $exit_code
    (( lvl-- ))
    foo.foo $lvl $exit_code
}

main() {
    local lvl=${1:-0}
    log.debug "$lvl"
    local exit_code=${2:-1}
    test $lvl -eq 0 && exit $exit_code
    (( lvl-- ))
    foo $lvl $exit_code
}


main $@
