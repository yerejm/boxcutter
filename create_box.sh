#!/bin/bash
set -e
export CM=nocm

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

    if [[ -z "$SKIP_ISO" && -f iso/exports ]]; then
        # get environment variables for iso filenames from local env
        source iso/exports
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

