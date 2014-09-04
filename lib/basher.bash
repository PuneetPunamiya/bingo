if [ -z ${BASHER_SOURCED+xxx} ]; then
BASHER_SOURCED=true

basher.run() {
    local cmds=( $(declare -F -p | cut -f3 -d ' ' | grep '^test.' ) )

    read -r -d '' all_tests <<-EOF_HELP || true
$BOLD${BLUE}Tests: $RESET
$(printf "  - %s\n" ${cmds[@]})

EOF_HELP

    #echo -e "$all_tests"
    mkdir -p tmp
    for t in ${cmds[@]} ; do
        #log.info "Running test: $t"
        local status=0
        ( $t ) 2>>tmp/stderr >>tmp/stdout || status=$?
        if [[ $status == 0 ]]; then
            echo -n "."
        else
            echo -n F
        fi
    done
    echo
}

basher._fail() {
    local caller_file=${BASH_SOURCE[2]##*/}
    local caller_line=${BASH_LINENO[1]}

    local caller_info="${WHITE}$caller_file${BLUE}(${caller_line}${BLUE})"
    local caller_fn=""
    if [ ${#FUNCNAME[@]} != 2 ]; then
        caller_fn="${FUNCNAME[1]:+${FUNCNAME[1]}}"
        caller_info+=" ${GREEN}$caller_fn"
    fi
    echo -e "$caller_info $RESET: $@"
    exit 1
}

basher.fail() {
    local caller_file=${BASH_SOURCE[1]##*/}
    local caller_line=${BASH_LINENO[0]}

    local caller_info="${WHITE}$caller_file${BLUE}(${caller_line}${BLUE})"
    local caller_fn=""
    if [ ${#FUNCNAME[@]} != 2 ]; then
        caller_fn="${FUNCNAME[1]:+${FUNCNAME[1]}}"
        caller_info+=" ${GREEN}$caller_fn"
    fi
    echo -e "${RED}${BOLD}FAIL $caller_info $RESET: $@"
    exit 1
}


basher.assert() {
    local actual=$1; shift
    local msg=${1:-"Expected $actual to be true but is false"}
    test $actual || basher._fail "$msg"
}

basher.assert_false() {
    local actual=$1; shift
    local msg=${1:-"Expected $actual to be false but is true"}

    test $actual && basher._fail "$msg"
}

basher.assert_equals() {
    local a=$1; shift
    local b=$1; shift

    local msg=${1:-"Expected $RED $a $RESET to be equal to $GREEN $b $RESET"}
    [[ "$a" == "$b" ]] || basher._fail "$msg"
    return 0
}


basher.run "$@"
fi ### end: BASHER_SOURCED
