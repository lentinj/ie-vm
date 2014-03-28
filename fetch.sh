#!/bin/sh -e

[ -z "$1" ] && { echo "Usage: $0 [url to IE.txt file]"; exit 1; }

TMP_DIR=./ie-vm-fetch-workdir
[ -e "$TMP_DIR" ] && rm -r $TMP_DIR/* || mkdir $TMP_DIR

# Fetch constituent parts
(cd $TMP_DIR && curl -O $(curl -s "$1" | dos2unix); )

# Extract VMDK from archive
(cd $TMP_DIR && unrar-nonfree x *part1*; )
tar -xvC $TMP_DIR -f $TMP_DIR/*.ova

# Convert into QCOW2
./qemu-img.vmdk3.hack.sh $TMP_DIR/*.vmdk
qemu-img convert -f vmdk -O qcow2 $TMP_DIR/*.vmdk $(basename $1 .For.LinuxVirtualBox.txt).qcow2

echo Finished! Tidying up...
rm -r $TMP_DIR
