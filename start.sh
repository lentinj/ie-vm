#!/bin/sh -e

NIC=virtio
[ "$1" = "--pcnet" ] && { NIC="pcnet"; shift; }

[ -n "$1" ] && IMG="$1" || IMG="$(ls -1t *.qcow2 | head -1)"

if [ "$NIC" = "virtio" ]; then
    if [ ! -e virtio*.iso ]; then
        # RH now have a package
        if [ -e "/usr/share/virtio-win/virtio-win.iso" ]; then
            echo "Using ISO from virtio-win package."
            ln -s /usr/share/virtio-win/virtio-win.iso ./virtio-win.iso;
        else
            echo Fetching virtIO drivers...
            wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
        fi
    fi
    CDIMAGE="-cdrom "virtio-win.iso
fi

qemu-system-x86_64 -enable-kvm \
    -drive "file=$IMG" \
    $CDIMAGE \
    -net nic,model=$NIC \
    -net user \
    -m 1024M \
    -monitor stdio \
    -snapshot -no-shutdown
