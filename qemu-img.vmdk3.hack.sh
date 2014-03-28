#!/bin/bash

# Why?
#
#    smite@desktop03:~/dev/puppet/manifests> vagrant mutate ubuntu-64-x64-vbox4210-nocm libvirt
#    Converting ubuntu-64-x64-vbox4210-nocm from virtualbox to libvirt.
#    qemu-img: 'image' uses a vmdk feature which is not supported by this qemu version: VMDK version 3
#    qemu-img: Could not open '/home/smite/.vagrant.d/boxes/ubuntu-64-x64-vbox4210-nocm/virtualbox/box-disk1.vmdk': Wrong medium type
#    Determining the virtual size of the disk image failed
#
# Bah! Humbug!
#
#    smite@desktop03:~/dev/puppet/manifests> ~/dev/one-liners/qemu-img.vmdk3.hack.sh /home/smite/.vagrant.d/boxes/ubuntu-64-x64-vbox4210-nocm/virtualbox/box-disk1.vmdk
#    /home/smite/.vagrant.d/boxes/ubuntu-64-x64-vbox4210-nocm/virtualbox/box-disk1.vmdk is VMDK3.
#     Patching to VMDK2.
#     Run this script again when you're done to patch it back.
#
# For realz?
#
#    smite@desktop03:~/dev/puppet/manifests> vagrant mutate ubuntu-64-x64-vbox4210-nocm libvirt
#    Converting ubuntu-64-x64-vbox4210-nocm from virtualbox to libvirt.
#        (98.57/100%)
#    The box ubuntu-64-x64-vbox4210-nocm (libvirt) is now ready to use.
#
# Fo' realz!
#
#    smite@desktop03:~/dev/puppet/manifests> ~/dev/one-liners/qemu-img.vmdk3.hack.sh /home/smite/.vagrant.d/boxes/ubuntu-64-x64-vbox4210-nocm/virtualbox/box-disk1.vmdk
#    File is VMDK2. Patching to VMDK3.
#    smite@desktop03:~/dev/puppet/manifests> 
#
# Thank you, come again!

VMDK=$1
FULLSIZE=`stat -c%s "$VMDK"`
VMDKFOOTER=$[$FULLSIZE - 0x400]
VMDKFOOTERVER=$[$VMDKFOOTER  + 4]

case "`xxd -ps -s $VMDKFOOTERVER -l 1 \"$VMDK\"`" in
  03) 
    echo -e "$VMDK is VMDK3.\n Patching to VMDK2.\n Run this script again when you're done to patch it back."
    echo -en '\x02' | dd conv=notrunc status=none oflag=seek_bytes seek=$[VMDKFOOTERVER]  of="$VMDK"
    ;;
  02) 
    echo "File is VMDK2. Patching to VMDK3."
    echo -en '\x03' | dd conv=notrunc status=none oflag=seek_bytes seek=$[VMDKFOOTERVER]  of="$VMDK"
    ;;
  default)
    echo "$VMDK is not VMDK3 or patched-VMDK3.\n"
  ;;
esac
