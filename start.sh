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

if [ "$NIC" = "virtio" ]; then
    LOCAL_ISO="$(ls -1t virtio*.iso | head -1)" 2>/dev/null
    if [ -n "${LOCAL_ISO}" ]; then
        echo "Using local ISO file ${LOCAL_ISO}"
        CDIMAGE="-cdrom ${LOCAL_ISO}"
    elif [ -e "/usr/share/virtio-win/virtio-win.iso" ]; then
        # RH now have a package
        echo "Using ISO from virtio-win package."
        CDIMAGE="-cdrom /usr/share/virtio-win/virtio-win.iso"
    else
        echo Fetching virtIO drivers...
        wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
        CDIMAGE="-cdrom virtio-win.iso"
    fi
fi

$QEMUSYS -enable-kvm \
    -drive "file=$IMG" \
    $CDIMAGE \
    -net nic,model=$NIC \
    -net user \
    -m "$RAM" \
    -monitor stdio \
    -vga std \
    -snapshot -no-shutdown
