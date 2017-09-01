#!/bin/bash
set -e
function check_arg {
    if [ -z "$1" ]; then
        echo "$2"
        echo "Usage: $0 <OS> <OP>"
        exit 1
    fi
}

function vm_dir {
    case "$1" in
        ubuntu*)
            VM=ubuntu
            ;;
        debian*)
            VM=debian
            ;;
        eval-win*|win*)
            VM=windows
            ;;
        osx*)
            VM=osx
            ;;
        freebsd*)
            VM=bsd
            ;;
        *)
            echo "Unsupported option $1"
            exit 1
            ;;
    esac
    echo "$VM"
}

function packer_build {
    VMDIR=$1
    OS=$2
    VARIANT=$3
    ISODIR=$4

    (cd "$VMDIR" && \
        packer build -only=virtualbox-iso \
                     -var-file="$VARIANT.json" \
                     -var "version=$(cat VERSION)" \
                     -var "iso_path=$ISODIR" \
                     "$OS.json" && \
        find . -name "$VARIANT*.box" -exec vagrant box add --force "$VARIANT" {} \;)
}

function make_box {
    OS=$1
    ISODIR=$2
    VMDIR=$(vm_dir "$OS")

    if [[ -f iso/exports ]]; then
        # get environment variables for iso filenames from local env
        source iso/exports
    fi

    case $OS in
        ubuntu*)
            packer_build "$VMDIR" ubuntu "$OS" "$ISODIR"
            ;;
        debian*)
            packer_build "$VMDIR" debian "$OS" "$ISODIR"
            ;;
        freebsd*)
            packer_build "$VMDIR" freebsd "$OS" "$ISODIR"
            ;;
        eval-win*|win*)
            (cd "$VMDIR" && \
                make "virtualbox/$OS" && \
                find . -name "$OS*.box" -exec vagrant box add --force "$OS" {} \;)
            ;;
        osx*)
            (cd "$VMDIR" && \
                sudo prepare_iso/prepare_iso.sh "$MAC_OSX_INSTALLER" dmg && \
                sudo rm -rf /tmp/veewee-osx* && \
                packer build -only=virtualbox-iso \
                             -var-file="$OS.json" \
                             -var "version=$(cat VERSION)" \
                             -var "iso_url=dmg/$MAC_OSX_BOOT_DMG" \
                             osx.json && \
                find . -name "$OS*.box" -exec vagrant box add --force "$OS" {} \;)
            ;;
        *)
            echo "Unknown $OS"
            exit 1
            ;;
    esac

    if [ "$?" -ne 0 ]; then
        echo "Box creation failed. Did you provide the right box? Try a list operation."
        exit $?
    fi
}

function vm_make {
    if [ "$1" = "all" ]; then
        OS="ubuntu debian windows osx freebsd"
    else
        OS=$1
    fi
    for os in $OS; do
        VMDIR=$(vm_dir "$os")
        MK_TARGET=$2
        (cd "$VMDIR" && make "$MK_TARGET")
    done
}

function vm_list {
    OS=$1
    VMDIR=$(vm_dir "$OS")
    find "$VMDIR" -name '*.json' | xargs -I{} basename {} .json
}

OS=$1
OP=$2
PROGPATH=$(dirname "$0")
BASEDIR=$(realpath "$PROGPATH")

check_arg "$OS" "Missing OS parameter."
check_arg "$OP" "Missing OP parameter."

case $OP in
    clean)
        vm_make "$OS" clean
        ;;
    make|remake)
        if [ "$OP" = "remake" ]; then vm_make "$OS" clean; fi
        make_box "$OS" "$BASEDIR/iso"
        ;;
    list)
        vm_list "$OS" list
        ;;
    *)
        echo "Unsupported operation $OP"
        echo "Available operations: clean, make, remake, list"
        ;;
esac

