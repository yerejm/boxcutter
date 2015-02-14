#!/bin/bash
set -e
export CM=nocm
ISO_DIR="$PWD/iso"

function check_arg {
    if [ -z "$1" ]; then
        echo "$2"
        echo "Usage: $0 <OS> <OP>"
        echo "Set SKIP_ISO to ignore local iso file and let box builder download it instead."
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
        *)
            echo "Unsupported option $1"
            exit 1
            ;;
    esac
    echo "$VM"
}

function make_box {
    OS=$1
    SKIP_ISO=$2
    VMDIR=$(vm_dir "$OS")

    if [ -z "$SKIP_ISO" ]; then
        case "$VMDIR" in
            ubuntu)
                ISO=$ISO_DIR/ubuntu-14.10-server-amd64.iso
                export UBUNTU1410_SERVER_AMD64=file://$ISO
                ;;
            debian)
                ISO=$ISO_DIR/debian-7.7.0-amd64-DVD-1.iso
                export DEBIAN77_AMD64=file://$ISO
                ;;
            windows)
                ISO=$ISO_DIR/9600.16384.WINBLUE_RTM.130821-1623_X64FRE_ENTERPRISE_EVAL_EN-US-IRM_CENA_X64FREE_EN-US_DV5.ISO
                export EVAL_WIN81_X64=file://$ISO
                ;;
            osx)
                # whitepsace needs to be make compatible
                ISO=$ISO_DIR/Install\ OS\ X\ Yosemite.app
                export MAC_OSX_10_10_YOSEMITE_INSTALLER=$(echo "$ISO" | sed 's/ /\\\ /g')
                ;;
            *)
                echo "Unsupported option $OS"
                exit 1
                ;;
        esac
        if [ ! -e "$ISO" ]; then
            echo "No ISO for $VMDIR at $ISO. Skipping..."
            exit 1
        fi
    fi

    (cd "$VMDIR" && \
        make "virtualbox/$OS" && \
        find . -name "$OS*.box" -exec vagrant box add --force "$OS" {} \;)
    if [ "$?" -ne 0 ]; then
        echo "Box creation failed. Did you provide the right box? Try a list operation."
        exit $?
    fi
}

function vm_make {
    VMDIR=$(vm_dir "$OS")
    MK_TARGET=$2
    (cd "$VMDIR" && make "$MK_TARGET")
}

OS=$1
OP=$2

check_arg "$OS" "Missing OS parameter."
check_arg "$OP" "Missing OR parameter."

case $OP in
    make|remake)
        if [ "$OP" = "remake" ]; then vm_make "$OS" clean; fi
        make_box "$OS" "$SKIP_ISO"
        ;;
    list)
        vm_make "$OS" list
        ;;
    *)
        echo "Unsupported operation $OP"
        echo "Available operations: make remake list"
        ;;
esac

