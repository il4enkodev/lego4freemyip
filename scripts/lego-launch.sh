#!/bin/bash

export LEGO_PATH=/etc/lego
HOOK=/usr/share/lego/hooks/copy-certs.sh

obtain() {
	lego -a --email=$LEGO_EMAIL --domains="*.$FREEMYIP_DOMAIN" --dns freemyip -k ec384 \
        run --must-staple --run-hook=$HOOK
}

renew() {
	lego -a  --email=$LEGO_EMAIL --domains="*.$FREEMYIP_DOMAIN" --dns freemyip -k ec384 \
        renew --must-staple --renew-hook=$HOOK
}

revoke() {
	local reason=${1:-0}
	lego -a --email=$LEGO_EMAIL --domains="*.$FREEMYIP_DOMAIN" --dns freemyip \
        revoke --reason=$reason
}

list() {
    lego list --accounts --names
}

usage() {
cat <<EOF
Lego wrapper for freemyip API.

USAGE: lego-launch [COMMAND]

COMMANDS:
    obtain      Obtain a letsencrypt wildcard certificate
    renew       Renew an existing certificate
    revoke      Revoke a certificate
    list        Display certificates and accounts information.

This script requires following environment variables to be set:
    LEGO_EMAIL          Email used for registration and recovery contact.
    FREEMYIP_DOMAIN     Freemyip domain
    FREEMIP_TOKEN       Account token

All environment variables will be loaded from /etc/lego/freemyip.env
EOF
}

source /usr/share/lego/scripts/lego-load-env.sh
load_lego_env

case $1 in
    obtain)	obtain ;;
    renew)  renew ;;
    revoke) revoke ;;
    list)   list ;;
    *) usage ;;
esac

clear_lego_env
