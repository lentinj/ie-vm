#!/bin/sh -e

# TODO: Dumps the iso into a directory structure
[ ! -e virtio*.iso ] && wget -r -l1 -A.iso http://alt.fedoraproject.org/pub/alt/virtio-win/latest/images/

qemu-system-x86_64 -enable-kvm \
    -drive "file=$1" \
    -cdrom virtio*.iso \
    -net nic,model=virtio \
    -net user \
    -m 1024M \
    -monitor stdio \
    -snapshot
