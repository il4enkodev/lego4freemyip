#!/bin/bash

# Available variables:
#    LEGO_ACCOUNT_EMAIL: the email of the account.
#    LEGO_CERT_DOMAIN: the main domain of the certificate.
#    LEGO_CERT_PATH: the path of the certificate.
#    LEGO_CERT_KEY_PATH: the path of the certificate key.

TARGET_DIR=/etc/ssl/sites/$LEGO_CERT_DOMAIN

if mkdir -p $TARGET_DIR; then
    cp $LEGO_CERT_PATH $TARGET_DIR/fullchain.crt
    chmod 644 $TARGET_DIR/fullchain.crt

    cp $LEGO_CERT_KEY_PATH $TARGET_DIR/private.key
    chmod 640 $TARGET_DIR/private.key
else
    echo "Failed to create directory $TARGET_DIR" >&2
    exit 1
fi
