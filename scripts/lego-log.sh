#!/bin/bash

# Logging levels:
#   DEBUG=4
#   INFO=3
#   WARN=2
#   ERROR=1

LEGO_LOG_LEVEL=${LEGO_LOG_LEVEL:-4}
LEGO_LOG_FILE=${LEGO_LOG_FILE:-/dev/stderr}
LEGO_LOG_DATE_FMT='%Y-%m-%d %T'

level_str() {
    case $1 in
        1) echo "ERROR" ;;
        2) echo "WARN" ;;
        3) echo "INFO" ;;
        *) echo "DEBUG" ;;
    esac
}

log() {
    local level=4
    local color=''
    local reset='\033[0m'
    case $1 in
        -d) shift 1 ;;
        -i) level=3; color='\033[0;34m'; shift 1 ;;
        -w) level=2; color='\033[0;33m'; shift 1 ;;
        -e) level=1; color='\033[0;31m'; shift 1 ;;
    esac
    if [ $LEGO_LOG_LEVEL -ge $level ]; then
        local msg="${color}${@}${reset}"
        if [[ -a $LEGO_LOG_FILE ]]; then
            if [[ -f $LEGO_LOG_FILE ]]; then
                # File exist and its a regular file
                msg="$(date +"$LEGO_LOG_DATE_FMT") [$(level_str $level)] ${@}"
            fi
        fi
        echo -e $msg >> $LEGO_LOG_FILE
    fi
}

