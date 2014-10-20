#!/bin/sh -e

if [ ! -e virtio*.iso ]; then
    echo Fetching virtIO drivers...
    wget -c --recursive --no-directories --accept-regex 'virtio.*\.iso' \
        http://alt.fedoraproject.org/pub/alt/virtio-win/stable/
fi

qemu-system-x86_64 -enable-kvm \
    -drive "file=$1" \
    -cdrom virtio*.iso \
    -net nic,model=virtio \
    -net user \
    -m 1024M \
    -monitor stdio \
    -snapshot -no-shutdown
