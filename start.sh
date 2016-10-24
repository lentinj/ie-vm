#!/bin/sh -e

NIC=virtio
[ "$1" = "--pcnet" ] && { NIC="pcnet"; shift; }

[ -n "$1" ] && IMG="$1" || IMG="$(ls -1t *.qcow2 | head -1)"

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

qemu-system-x86_64 -enable-kvm \
    -drive "file=$IMG" \
    $CDIMAGE \
    -net nic,model=$NIC \
    -net user \
    -m 1024M \
    -monitor stdio \
    -vga std \
    -snapshot -no-shutdown
