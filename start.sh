#!/bin/sh -e

if [ ! -e virtio*.iso ]; then
    echo Fetching virtIO drivers...
    curl -O http://alt.fedoraproject.org/pub/alt/virtio-win/latest/images/virtio-win-0.1-74.iso
fi

qemu-system-x86_64 -enable-kvm \
    -drive "file=$1" \
    -cdrom virtio*.iso \
    -net nic,model=virtio \
    -net user \
    -m 1024M \
    -monitor stdio \
    -snapshot
