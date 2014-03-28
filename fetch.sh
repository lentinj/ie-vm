#!/bin/sh -e

[ -z "$1" ] && { echo "Usage: $0 [url to IE.txt file]"; exit 1; }

TMP_DIR=./ie-vm-fetch-workdir
[ -d "$TMP_DIR" ] && rm -r $TMP_DIR ; mkdir $TMP_DIR

# Fetch constituent parts
for url in $(curl -s "$1" | dos2unix); do
    (cd $TMP_DIR && curl -O $url; ) &
done
wait

# Extract VMDK from archive
unrar-nonfree p -inul $TMP_DIR/*part1* | tar -xvC $TMP_DIR

# Convert into QCOW2
./qemu-img.vmdk3.hack.sh $TMP_DIR/*.vmdk
qemu-img convert -f vmdk -O qcow2 $TMP_DIR/*.vmdk $(basename $1 .For.LinuxVirtualBox.txt).qcow2

echo Finished! Delete $TMP_DIR to tidy up
