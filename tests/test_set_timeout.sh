#! /usr/bin/env bash
set  -u #-x
declare -r TEST_DIR=$(cd $(dirname "$0") && pwd)

oneTimeTearDown() {
    rm -f $TEST_DIR/{settings.conf,defaults.conf}
}

oneTimeSetUp() {
    touch $TEST_DIR/{settings.conf,defaults.conf}
}

oneTimeSetUp
source $TEST_DIR/../lib/bingo.bash

poll_until() {
    local timeout=$1; shift
    local msg="${1:-''}"; shift

    local -i slept=1
    while [[ $slept -lt $timeout ]]; do
        log.debug " $msg ... $slept"
        sleep 1
        (( slept++ ))
    done
}


handler_x() {
    local arg=${1:-'no arg'}
    log.debug "Custom handler ... $arg"
    poll_until 3
    exit 0
}

main() {
    local -i run_timeout=${1:-5}
    local -i script_timeout=${2:-15}

    script.set_timeout $script_timeout
    #script.set_timeout $script_timeout 8 handler_x
    on_exit poll_until 8 " on exit poll 8"
    log.info "Runs for $run_timeout, and times out in $script_timeout"
    poll_until $run_timeout  'test this out...'

    log.debug "All is well ..."
}



DEBUG=${DEBUG:-false}
main "$@"
oneTimeTearDown
