#!/bin/bash

LEGO_LOG_FILE=/dev/stderr
source ../scripts/lego-log.sh

test_console_output() {
    echo "TEST CONSOLE OUTPUT"
    log -d "Simple debug message"
    log -i "Simple info message"
    log -w "Simple warning message"
    log -e "Simple error message"
}

test_file_output() {
    echo "TEST FILE OUTPUT"
    LEGO_LOG_FILE=lego_test.log
    log -d "Simple debug message"
    log -i "Simple info message"
    log -w "Simple warning message"
    log -e "Simple error message"
}

test_console_output
test_file_output
