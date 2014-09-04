#!/bin/bash
set  -u

declare -r TEST_DIR=$(cd $(dirname "$0") && pwd)
source $TEST_DIR/../lib/bingo.bash


test.log_warn() {
    log.warn "A test. warn message"
    return 0
}

test.multiple_args_log_info() {
    log.info "A test. warn message" "another test." message
    return 0
}


test.multliple_args_auto () {
    local x="$@"
    local tx=$(log.info "$x")
    local ta=$(log.info "$@")
    basher.assert_equals "Array and single equal:" "$ta" "$tx"
    return 0
}

test.defined() {
    u='[### BUG ###] A test. warn message'
    basher.assert $u

    unset FooBar
    basher.assert FooBar 'defined u'
    is_defined u || basher.fail "u is NOT  defined"
    not_empty u || basher.fail "u is NOT  defined"
    is_defined FooBAaR && basher.fail "FooBAaR is  defined"
    return 0
}

test.log_fatal() {
    (log.error "A Fatal message without exit value")
    local val=$?
    basher.assert_equals  $val 127 "log.fatal 127"
    ( log.error 18 "A Fatal message with exit value" )
    local val=$?

    basher.assert_equals "log.fatal 18" $val 18
    return 0
}

source ../lib/basher.bash
