#!/bin/sh -e

NIC="virtio"
QEMUSYS="qemu-system-x86_64"
IMG="$(ls -1t *.qcow2 | head -1)"
RAM="1024M"

# support more options
# modified version of https://gist.github.com/adamhotep/895cebf290e95e613c006afbffef09d7
usage() {
    echo "start.sh [--pcnet] [--qemu-bin qemuSystemBinary] [-m memoryForSystem] [(image filename)]"
    exit
}

reset=true
for arg in "$@"
do
    if [ -n "$reset" ]; then
      unset reset
      set --      # this resets the "$@" array so we can rebuild it
    fi
    case "$arg" in
       --help)    set -- "$@" -h ;;
       --pcnet)   set -- "$@" -p ;;
       --qemu-bin) set -- "$@" -b ;;
       --image)   set -- "$@" -i ;;
       # pass through anything else
       *)         set -- "$@" "$arg" ;;
    esac
done
# now we can process with getopt
while getopts ":hpb:i:m:" opt; do
    case $opt in
        h)  usage ;;
        p) NIC="pcnet" ;;
        b) QEMUSYS=$OPTARG ;;
        m) RAM=$OPTARG ;;
        \?) usage ;;
        :)
        echo "option -$OPTARG requires an argument"
        usage
        ;;
    esac
done
shift $((OPTIND-1))

# If there's a positional argument, then use this as image name
[ -n "$1" ] && { IMG="$1"; shift; }

EXTRA_ARGS=""

if [ "$NIC" = "virtio" ]; then
    LOCAL_ISO="$(ls -1t virtio*.iso | head -1)" 2>/dev/null
    if [ -n "${LOCAL_ISO}" ]; then
        echo "Using local ISO file ${LOCAL_ISO}"
        EXTRA_ARGS="${EXTRA_ARGS} -cdrom ${LOCAL_ISO}"
    elif [ -e "/usr/share/virtio-win/virtio-win.iso" ]; then
        # RH now have a package
        echo "Using ISO from virtio-win package."
        EXTRA_ARGS="${EXTRA_ARGS} -cdrom /usr/share/virtio-win/virtio-win.iso"
    else
        echo Fetching virtIO drivers...
        wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
        EXTRA_ARGS="${EXTRA_ARGS} -cdrom virtio-win.iso"
    fi
fi

OVMF_BIN="${OVMF_BIN-/usr/share/qemu/OVMF.fd}"
if echo ${IMG} | grep -q '.Win10.'; then
    # Win10 images require EFI for booting
    [ -f "${OVMF_BIN}" ] || {
        echo "${OVMF_BIN} is not avialable, install the ovmf package or set OVMF_BIN to the location of OVMF.fd"
        exit 1
    }
    EXTRA_ARGS="${EXTRA_ARGS} -bios ${OVMF_BIN}"
fi

$QEMUSYS -enable-kvm \
    -drive "file=$IMG" \
    ${EXTRA_ARGS} \
    -net nic,model=$NIC \
    -net user \
    -m "$RAM" \
    -usb -device usb-ehci,id=ehci \
    -device usb-tablet \
    -monitor stdio \
    -vga std \
    -snapshot -no-shutdown
