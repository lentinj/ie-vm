#!/bin/sh -e

# Have QEMU share the shared/ folder if smbd is installed
# Only do this if root, however, as there are problems with smbd if qemu isn't run as root
if which smbd 2>&1 && [[ $EUID -eq 0 ]] ; then
  USE_SHARED="${USE_SHARED:--smb $(pwd)/shared}"
else
  USE_SHARED=""
fi

# Allow passing a commandline to override
if [ -n "$1" ]; then
  eval "$@"
  exit $?
fi

# Consider these as examples of how to run a KVM guest

if [ -z "$SPICE" ]; then
  # Use VNC by default
  qemu-system-x86_64 -enable-kvm \
      -drive "file=$1" \
      -cdrom virtio*.iso \
      -net nic,model=virtio \
      -net user \
      -m 1024M \
      -monitor stdio \
      -snapshot -no-shutdown \
      -redir tcp:13389::3389 \
      -usb \
      -usbdevice tablet \
      --vnc 0.0.0.0:1 \
      $USE_SHARED
else
  # Use SPICE if it is desired
  qemu-system-x86_64-spice -enable-kvm \
      -drive "file=$1" \
      -cdrom virtio*.iso \
      -net nic,model=virtio \
      -net user \
      -m 1024M \
      -monitor stdio \
      -snapshot -no-shutdown \
      -redir tcp:13389::3389 \
      -usb \
      -usbdevice tablet \
      -spice port=5901,addr=0.0.0.0,disable-ticketing \
      -device virtio-serial-pci \
      -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
      -chardev spicevmc,id=spicechannel0,name=vdagent \
      -vga qxl \
      $USE_SHARED
fi
