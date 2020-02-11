#!/bin/sh -e

NIC="virtio"
VGA="qxl"
DISK="ide"
QEMUSYS="$(which qemu-system-x86_64)"
IMG="$(ls -1t *.qcow2 | head -1)"
RAM="1024M"

# support more options
# modified version of https://gist.github.com/adamhotep/895cebf290e95e613c006afbffef09d7
usage() {
    cat <<EOF
    usage: $0 (options) [(image filename)]

    --efi                  Use EFI to boot instead of legacy MBR
    --qemu-bin (path)      Path to QEMU binary, default "${QEMUSYS}"
    --ram (amount)         Amount of VM RAM, default "${RAM}"
    --no-virtio            Emulate devices that don't require virtio drivers (i.e. std VGA/pcnet NIC)
    --disk-virtio          Force the disk to also use virtio. Boot without this first and install SCSI drivers
    (image filename)       QEMU image to load, defaut "${IMG}"

    Any additional QEMU arguments can be given with the EXTRA_ARGS environment variable, e.g.
        EXTRA_ARGS="-cdrom refind-cd-0.11.4.iso -boot d" $0
EOF
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
       --efi)   set -- "$@" -e ;;
       --pcnet)   set -- "$@" -p ;;
       --qemu-bin) set -- "$@" -b ;;
       --ram) set -- "$@" -m ;;
       --no-virtio)   set -- "$@" -n ;;
       --disk-virtio)   set -- "$@" -d ;;
       # pass through anything else
       *)         set -- "$@" "$arg" ;;
    esac
done
# now we can process with getopt
while getopts ":hepb:m:nd" opt; do
    case $opt in
        h)  usage ;;
        e) EFIBOOT="T" ;;
        p) NIC="pcnet" ;;
        b) QEMUSYS=$OPTARG ;;
        m) RAM=$OPTARG ;;
        n) NIC="pcnet" ; VGA="std" ;;
        d) DISK="virtio" ;;
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

EXTRA_ARGS="${EXTRA_ARGS-}"

if [ "$NIC" = "virtio" ] || [ "$VGA" = "qxl" ] || [ "$DISK" = "virtio" ]; then
    if [ -e "/usr/share/virtio-win/virtio-win.iso" ]; then
        # RH now have a package
        echo "Using ISO from virtio-win package."
        EXTRA_ARGS="${EXTRA_ARGS} -cdrom /usr/share/virtio-win/virtio-win.iso"
    else
        VIRTIO_ISO="$(wget -q -S --spider https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso 2>&1 | grep -oE 'virtio-win-[0-9.]+.iso')"
        [ -e "${VIRTIO_ISO}" ] || {
            echo Fetching virtIO drivers...
            wget -O "${VIRTIO_ISO}" https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
        }
        EXTRA_ARGS="${EXTRA_ARGS} -cdrom ${VIRTIO_ISO}"
    fi

    if [ "$DISK" != "virtio" ]; then
        # A dummy disk whose only purpose is to trigger VirtIO driver installs
        VIRTIO_TRIGGER="virtio-driver-install-trigger.qcow2"
        [ -f "${VIRTIO_TRIGGER}" ] || qemu-img create -f qcow2 "${VIRTIO_TRIGGER}" 1M
        EXTRA_ARGS="${EXTRA_ARGS} drive file=${VIRTIO_TRIGGER},if=virtio"
    fi
fi

OVMF_BIN="${OVMF_BIN-/usr/share/qemu/OVMF.fd}"
if [ -n "${EFIBOOT-}" ]; then
    [ -f "${OVMF_BIN}" ] || {
        echo "${OVMF_BIN} is not avialable, install the ovmf package or set OVMF_BIN to the location of OVMF.fd"
        exit 1
    }
    EXTRA_ARGS="${EXTRA_ARGS} -bios ${OVMF_BIN}"
fi

$QEMUSYS -enable-kvm \
    -cpu host \
    -drive file="$IMG",if="$DISK" \
    ${EXTRA_ARGS} \
    -net nic,model=$NIC \
    -net user \
    -m "$RAM" \
    -usb -device usb-ehci,id=ehci \
    -device usb-tablet \
    -monitor stdio \
    -vga "${VGA}" \
    -snapshot -no-shutdown
