if [ -z ${BINGO_SOURCED+xxx} ]; then
BINGO_SOURCED=true

set -e -u
declare -a __init_exit_todo_list=()
declare -i __init_script_exit_code=0

declare -r BINGO_SCRIPT_PATH=$0
declare -r BINGO_SCRIPT_FILENAME=$(basename $0)
declare -r BINGO_LIB_DIR=$(readlink -f ${BASH_SOURCE[0]%/*})

declare -r RED='\e[31m'
declare -r GREEN='\e[32m'
declare -r YELLOW='\e[33m'
declare -r BLUE='\e[34m'
declare -r MAGENTA='\e[35m'
declare -r CYAN='\e[36m'
declare -r WHITE='\e[37m'

declare -r BOLD='\e[1m'
declare -r RESET='\e[0m'

log.debug() {
    local caller_file=${BASH_SOURCE[1]##*/}
    local caller_line=${BASH_LINENO[0]}

    local caller_info="${WHITE}$caller_file${BLUE}(${caller_line}${BLUE})"
    local caller_fn=""
    if [ ${#FUNCNAME[@]} != 2 ]; then
        caller_fn="${FUNCNAME[1]:+${FUNCNAME[1]}}"
        caller_info+=" ${GREEN}$caller_fn"
    fi
    echo -e "$caller_info $RESET: $@" >&2
}



log.info() {
    echo -e "$GREEN${BOLD}INFO:$RESET" "$@"
}


log.warn() {
    echo -e "${RED}WARNING:$RESET" "$@"
}


log.error() {
    echo -e "$RED${BOLD}ERROR:$RESET" "$@"
}

debug.print_callstack() {
    local i=0;
    local cs_frames=${#BASH_SOURCE[@]}

    echo "--------------------------------------------------"
    echo "Traceback ... "
    for (( i=$cs_frames - 1; i >= 2; i-- )); do
        local cs_file=${BASH_SOURCE[i]}
        local cs_fn=${FUNCNAME[i]}
        local cs_line=${BASH_LINENO[i-1]}

        # extract the line from the file
        local line=$(sed -n "${cs_line}{s/^ *//;p}" "$cs_file")

        echo -e "  $cs_file[$cs_line]:" \
            "$cs_fn:\t" \
            "$line"
    done
    echo "--------------------------------------------------"
}

# on_exit_handler <exit-value>
_on_exit_handler() {
    # store the script exit code to be used later
    __init_script_exit_code=${1:-0}

    # print callstack
    test $__init_script_exit_code -eq 0 || debug.print_callstack

    echo "Exit cleanup ... ${__init_exit_todo_list[@]} "
    for cmd in "${__init_exit_todo_list[@]}" ; do
        echo "    running: $cmd"
        # run commands in a subshell so that the failures
        # can be ignored
        ($cmd) || {
            local cmd_type=$(type -t $cmd)
            local cmd_text="$cmd"
            local failed="FAILED"
            echo "    $cmd_type: $cmd_text - $failed to execute ..."
        }
    done
}

on_exit() {
    local cmd="$*"

    local n=${#__init_exit_todo_list[*]}
    if [[ $n -eq 0 ]]; then
        trap '_on_exit_handler $?' EXIT
        __init_exit_todo_list=("$cmd")
    else
        __init_exit_todo_list=("$cmd" "${__init_exit_todo_list[@]}") #execute in reverse order
    fi
}

init.print_result() {
    local exit_code=$__init_script_exit_code
    if [[  $exit_code == 0 ]]; then
        echo "$BINGO_SCRIPT_FILE: PASSED"
    else
        echo "$BINGO_SCRIPT_FILE: FAILED" \
             " -   exit code: [ $exit_code ]"
    fi
}


execute() {
  log.info "Execute command:  $@"
  ${DRY_RUN:-false} || "$@"
}


# script._poll_parent timeout interval
#
# polls if the parent process $$ exists at every <interval>
# until <timeout>.
# returns:
#   0 if parent process isn't found
#   1 if it exists
script._poll_parent() {
    local -i timeout=$1; shift
    local -i interval=${1:-1}

    if [[ $interval -gt $timeout ]]; then
        interval=$(($timeout - 1))
    fi

    local -i slept=1
    while [[ $slept -lt $timeout ]]; do
        sleep $interval
        kill -s 0 $$ 2>/dev/null || return 0
        slept=$((slept + $interval))

        if [[ $(($slept + $interval)) -gt $timeout ]]; then
            interval=$(($timeout - $slept))
        fi
    done
    return 1
}


#script.set_timeout <soft-timeout> [hard-timeout] [timeout-handler]
# sends HUP after soft-timeout and then KILL if process doesn't
# exit after <hard-timeout>
# hard-timeout  [ default: 30 seconds ]
script.set_timeout() {
    local -i soft_timeout=$1; shift
    local -i hard_timeout=${1:-30}
    [[ $# -ge 1 ]] && shift

    _timeout_handler() { exit 1; }

    local handler=${1:-'_timeout_handler'}
    [[ $# -ge 1 ]] && shift

    trap  "$handler $@" SIGHUP
    (
        script._poll_parent $soft_timeout 4 && exit 0

        log.warn "$RED${BOLD}$BINGO_SCRIPT_FILE $RESET" \
            "timed out after $soft_timeout;" \
            "sending ${RED}SIGHUP$RESET to cleanup"
        kill -s HUP $$

        script._poll_parent $hard_timeout && exit 0

        log.warn "$RED${BOLD}$BINGO_SCRIPT_FILE $RESET" \
            "did not finish cleaning up in $hard_timeout;" \
            "sending ${RED}SIGKILL$RESET to $$"
        kill -s KILL $$
    )&
}

time.to_seconds () {
    IFS=: read h m s <<< "$1"
    #echo "h: $h | m: $m | s: $s"
    [[ -z $s ]] && [[ -z $m ]] && { s=$h; h=; }
    [[ -z $s ]] && { s=$m; m=; }
    [[ -z $m ]] && { m=$h; h=; }
    #echo "h: $h | m: $m | s: $s"
    echo $(( 10#$h * 3600 + 10#$m * 60 + 10#$s ))
}

is_function() {
    local method=$1; shift
    [[ $(type -t $method) == "function" ]]
}

is_defined() {
    local var=$1; shift
    [[ ${!var+xxxx} == 'xxxx' ]] && [[ ${!var+axbx} == 'axbx' ]]
}

not_empty() {
    local var=$1; shift
    is_defined $var && test -n $var
}

is_dir() {
    local path=$1; shift
    [[ -d "$path" ]]
}

is_file() {
    local path=$1; shift
    [[ -f "$path" ]]
}

str.to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

str.to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

fi # BINGO_SOURCED
