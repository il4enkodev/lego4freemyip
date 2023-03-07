#!/bin/bash

export LEGO_PATH=/etc/lego
LEGO_ENV=$LEGO_PATH/freemyip.env

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
        source $LEGO_ENV
        if [[ $? -ne 0 ]]; then
            echo "Failed to load environment variables from $LEGO_ENV" >&2
            exit $1
        fi
        check_vars /dev/stderr
    fi
}

clear_lego_env() {

}
