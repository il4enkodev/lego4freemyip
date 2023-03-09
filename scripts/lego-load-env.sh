#!/bin/bash

LEGO_HOME_DIR=/etc/lego
ENV_FILE=$LEGO_HOME_DIR/freemyip.env

check_vars() {
	local out=${1:-/dev/null}
	for v in LEGO_EMAIL FREEMYIP_DOMAIN FREEMYIP_TOKEN; do
		if [ -z "${!v}" ]; then
			echo "Variable $v is not set" > $out
			return 1
		fi
	done
}

load_lego_env() {
    if ! check_vars; then
        source $ENV_FILE
        if [[ $? -ne 0 ]]; then
            echo "Failed to load environment variables from $ENV_FILE" >&2
            exit $1
        fi
        check_vars /dev/stderr
    fi
}

clear_lego_env() {
    unset LEGO_EMAIL
    unset FREEMYIP_DOMAIN
    unset FREEMYIP_TOKEN
}
