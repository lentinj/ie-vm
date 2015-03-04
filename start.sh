#!/bin/sh -e

NIC=virtio
[ "$1" = "--pcnet" ] && { NIC="pcnet"; shift; }

[ -n "$1" ] && IMG="$1" || IMG="$(ls -1t *.qcow2 | head -1)"

if [ "$NIC" = "virtio" ]; then
    if [ ! -e virtio*.iso ]; then
        echo Fetching virtIO drivers...
        VIRTIO_ISO=$(wget -q -O - http://alt.fedoraproject.org/pub/alt/virtio-win/stable/ \
                    | grep -oiE 'virtio-win-[0-9.\-]+iso' \
                    | head -1)
        wget http://alt.fedoraproject.org/pub/alt/virtio-win/stable/${VIRTIO_ISO}
    fi
    CDIMAGE="-cdrom "virtio*.iso
fi

qemu-system-x86_64 -enable-kvm \
    -drive "file=$IMG" \
    $CDIMAGE \
    -net nic,model=$NIC \
    -net user \
    -m 1024M \
    -monitor stdio \
    -snapshot -no-shutdown
