#!/bin/sh -e

[ -z "$1" ] && { echo "Usage: $0 [path of RAR downloads]"; exit 1; }
TMP_DIR="$1"
[ -d "$TMP_DIR" ] || { echo $TMP_DIR missing ; exit 1; }

# Extract VMDK from archive
unrar-nonfree p -inul $TMP_DIR/*part1* | tar -xvC $TMP_DIR

# Convert into QCOW2
./qemu-img.vmdk3.hack.sh $TMP_DIR/*.vmdk
qemu-img convert -f vmdk -O qcow2 $TMP_DIR/*.vmdk "$(basename $TMP_DIR/*.ovf .ovf).qcow2"

echo Finished! Delete $TMP_DIR to tidy up
