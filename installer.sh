#!/bin/bash

LEGO_INSTALL_DIR=/usr/local/bin
LEGO_WRAPPERS_DIR=/usr/share/lego
LEGO_SCRIPT_DIR=$LEGO_WRAPPERS_DIR/scripts
LEGO_HOOKS_DIR=$LEGO_WRAPPERS_DIR/hooks
LEGO_CERTS_DIR=/etc/ssl/sites

LEGO_HOME_DIR=/etc/lego

LEGO_USER=lego
LEGO_GROUP=ssl-certs

LEGO_LOG_LEVEL=4 # DEBUG
source scripts/lego-log.sh


find_latest_lego_version() {
    log -d "Searching for latest lego version..."
    local url="https://github.com/go-acme/lego/releases.atom"
    local feed="$(curl --silent --fail $url)"
    if [ $? -ne 0 ]; then
        echo "Error fetching feed!" >&2
        return $?
    fi
    if ! command -v xmllint &> /dev/null; then
        log -e "xmllint is not found but required as a dependency for this script"
        log -e "Please install it and try again"
        return 1
    else
        echo $feed | xmllint --xpath "//*[local-name()='entry'][1]/*[local-name()='title']/text()" -
    fi
}

determine_arch() {
    log -d "Checking arch..."
    local res=''
    shopt -s nocasematch
    case "$(uname -m)" in
        x86_64*) res="amd64" ;;
        i386*|i486*|i586*|i686*) res="386" ;;
        aarch64*|armv8*) res="arm64" ;;
        armv7*) res="armv7" ;;
    esac
    shopt -u nocasematch
    if [[ -n $res ]]; then
        echo $res
    else
        log -e "Unsupported arch: $(uname -m)"
        return 1
    fi
}

determine_os() {
    log -d "Checking OS..."
    local res=''
    shopt -s nocasematch
    case $(uname) in
        linux*|android*) res=linux ;;
        darwin*) res=darvin ;;
        freebsd*) res=freebsd ;;
        openbsd*) res=openbsd ;;
    esac
    shopt -u nocasematch
    if [[ -n $res ]]; then
        echo $res
    else
        log -e "Unsupported OS: $(uname -m)"
        return 1
    fi
}

install_lego() {
    local version os arch
    log -d "Preparing to install lego"

    os=$(determine_os) || exit 1
    arch=$(determine_arch) || exit 1
    version=$(find_latest_lego_version) || exit 1

    local filename="lego_${version}_${os}_${arch}.tar.gz"
    local download_url="https://github.com/go-acme/lego/releases/download/${version}/${filename}"

    log -d "Downloading $download_url"
    local filepath="/tmp/${filename}"

    if ! curl --silent --fail --show-error -L -o "$filepath" "$download_url"; then
        log -e "Download failed (url: $download_url)"
        exit 1
    fi

    log -d "Unpaking lego binary into $LEGO_INSTALL_DIR"
    if ! tar -C "$LEGO_INSTALL_DIR" -xf $filepath --no-same-owner lego; then
        log -e "Failed to unpack lego binary into $LEGO_INSTALL_DIR"
        exit 1
    fi

    rm $filepath

    log -i "Successfully installed lego $version\n"
}

check_root() {
    local script_name=$1
    if [ $UID -ne 0 ]; then
        log -e "You should execute this script as superuser."
        log -e "Run: sudo $script_name"
        exit 1
    fi
}

install_scripts() {
    log -d "Creating group '$LEGO_GROUP'"
    groupadd $LEGO_GROUP

    log -d "Creating user '$LEGO_USER'"
    useradd -r -s /bin/false -G $LEGO_GROUP -d "$LEGO_HOME_DIR" $LEGO_USER

    log -d "Installing scripts into $LEGO_WRAPPERS_DIR"
    mkdir -p {$LEGO_WRAPPERS_DIR,$LEGO_HOME_DIR}
    cp -r {scripts,hooks} $LEGO_WRAPPERS_DIR
    chown -R $LEGO_USER:$LEGO_GROUP {$LEGO_WRAPPERS_DIR,$LEGO_HOME_DIR}

    log -d "Creating symlinks"
    ln -s $LEGO_WRAPPERS_DIR/scripts/lego-launch.sh /usr/local/bin/lego-launch

    log -d "Creating directory $LEGO_CERTS_DIR\n"
    mkdir -p $LEGO_CERTS_DIR
    chgrp $LEGO_GROUP $LEGO_CERTS_DIR
    chmod 775 $LEGO_CERTS_DIR
}

domain=''
token=''
parse_url() {
    local url="$1"
    local regexpr="https://freemyip\.com/update\?token=([0-9a-f]{24})&domain=([a-zA-Z0-9\.-]{14,})"
    if [[ $url =~ $regexpr ]]; then
        token="${BASH_REMATCH[1]}"
        domain="${BASH_REMATCH[2]}"
    else
        log -e "Failed to parse url"
        exit 1
    fi
}

register() {
    log -d "Registering user account"
    local env_file=$LEGO_HOME_DIR/freemyip.env

    local reset="\033[0m"
    local green='\033[0;32m'

    echo "Enter your credential"
    read -p "$(echo -e $green"Freemyip url: "$reset)" url
    parse_url $url

    read -p "$(echo -e $green"Email: "$reset)" email
    log -d "Generating env file with credentials ($env_file)"

tee $LEGO_HOME_DIR/freemyip.env > /dev/null <<EOF
export LEGO_EMAIL=$email
export FREEMYIP_DOMAIN=$domain
export FREEMYIP_TOKEN=$token
EOF


    chown -R $LEGO_USER:$LEGO_GROUP $LEGO_HOME_DIR
    chmod 640 $LEGO_HOME_DIR/freemyip.env

    log -i "User account successfuly created\n"
}

# ----- MAIN ----------

check_root $0
install_lego
install_scripts
register

log -i "Obtaining certificates..."
lego-launch obtain

log -i "\nDone!"
log -i "Use lego-launch for renew/rewoke existing certificates"
