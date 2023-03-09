#!/bin/bash

# Available variables:
#    LEGO_ACCOUNT_EMAIL: the email of the account.
#    LEGO_CERT_DOMAIN: the main domain of the certificate.
#    LEGO_CERT_PATH: the path of the certificate.
#    LEGO_CERT_KEY_PATH: the path of the certificate key.

#    LEGO_EMAIL: email used for registration and recovery contact.
#    FREEMYIP_DOMAIN: freemyip domain
#    FREEMIP_TOKEN: account token

source /usr/share/lego/scripts/lego-log.sh
log -i "Running copy-certs hook..."

TARGET_DIR=/etc/ssl/sites/$FREEMYIP_DOMAIN

if mkdir -p $TARGET_DIR; then
    log -i "Copy certificates into $TARGET_DIR"
    cp $LEGO_CERT_PATH $TARGET_DIR/fullchain.crt
    chmod 644 $TARGET_DIR/fullchain.crt

    cp $LEGO_CERT_KEY_PATH $TARGET_DIR/private.key
    chmod 640 $TARGET_DIR/private.key

    if [ $UID -e 0 ]; then
        chown -R lego:ssl-certs $TARGET_DIR
        chmod 755 $TARGET_DIR
    fi
else
    log -e "Failed to create directory $TARGET_DIR"
    exit 1
fi
