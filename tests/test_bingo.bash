#! /usr/bin/env bash
set -e -u

declare -r SCRIPT_DIR=$(cd `dirname $0` && pwd)
source $SCRIPT_DIR/../lib/bingo.bash

test.bingo_vars() {
    basher.assert_equals $BINGO_LIB_DIR $( readlink -f $SCRIPT_DIR/../lib)
    return 0
}

source $SCRIPT_DIR/../lib/basher.bash
