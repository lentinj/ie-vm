#!/bin/sh -e

TMP_DIR=./ie-vm-fetch-workdir
[ -d "$TMP_DIR" ] || { echo $TMP_DIR missing ; exit 1; }

# Extract VMDK from archive
unrar-nonfree p -inul $TMP_DIR/*part1* | tar -xvC $TMP_DIR

# Convert into QCOW2
./qemu-img.vmdk3.hack.sh $TMP_DIR/*.vmdk
qemu-img convert -f vmdk -O qcow2 $TMP_DIR/*.vmdk "$(basename $TMP_DIR/*.ovf .ovf).qcow2"

echo Finished! Delete $TMP_DIR to tidy up
