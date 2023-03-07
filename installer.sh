#!/bin/bash

LEGO_INSTALL_DIR=/usr/local/bin
LEGO_WRAPPERS_DIR=/usr/share/lego
LEGO_SCRIPT_DIR=$LEGO_WRAPPERS_DIR/scripts
LEGO_HOOKS_DIR=$LEGO_WRAPPERS_DIR/hooks

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
    echo $feed | xmllint --xpath "//*[local-name()='entry'][1]/*[local-name()='title']/text()" -
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

    os=$(determine_os) || return 1
    arch=$(determine_arch) || return 1
    version=$(find_latest_lego_version) || return 1

    local filename="lego_${version}_${os}_${arch}.tar.gz"
    log -d "Downloading $filename"

    local download_url="https://github.com/go-acme/lego/releases/download/${version}/${filename}"
    local filepath="/tmp/${filename}"

    curl --silent --fail --show-error -o "$filepath" "$download_url" \
        || log -e "Download failed (url: $download_url)"; exit 1

    log -d "Unpaking lego binary into $LEGO_INSTALL_DIR"
    tar -C "$LEGO_INSTALL_DIR" -xf $filepath --no-same-owner lego \
        || log -e "Failed to unpack lego binary into $LEGO_INSTALL_DIR"; exit 1

    rm $filepath

    log -i "Successfully installed lego $version"
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
    log -d "Creating user '$LEGO_USER' and group '$LEGO_GROUP'"
    useradd -r -s /bin/false -g $LEGO_GROUP -d $LEGO_WORKING_DIR $LEGO_USER

    log -d "Installing scripts into $LEGO_WRAPPERS_DIR"
    mkdir -p {$LEGO_WRAPPERS_DIR,$LEGO_HOME_DIR}
    cp -r {scripts,hooks} $LEGO_WRAPPERS_DIR
    chown -R $LEGO_USER:$LEGO_GROUP {$LEGO_WRAPPERS_DIR,$LEGO_HOME_DIR}

    log -d "Creating symlinks"
    ln -s $LEGO_WRAPPERS_DIR/scripts/lego-launch.sh /usr/local/bin/lego-launch
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
    echo "Enter your credential"
    input -p "freemyip url: " url
    parse_url $url

    input -p "email: " email
    log -d "Generating env file with credentials"

tee $LEGO_HOME_DIR/freemyip.env > /dev/null <<EOF
export LEGO_EMAIL=$email
export FREEMYIP_DOMAIN=$domain
export FREEMYIP_TOKEN=$token
EOF
}

# ----- MAIN ----------

check_root $0
install_lego
register
