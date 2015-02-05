#!/bin/sh -e

[ -z "$1" ] && { echo "Usage: $0 [url to IE.txt file]"; exit 1; }

SHORTNAME="$(basename "$1" .txt)"
TMP_DIR="./workdir-$SHORTNAME"

# Fetch constituent parts
wget -q -O - "$1" | dos2unix | xargs -n1 -P8 wget -c -P "$TMP_DIR"

cat $TMP_DIR/*.zip.* > $SHORTNAME.zip
rm -f $TMP_DIR/*.zip.*
unzip $SHORTNAME.zip
rm -f $SHORTNAME.zip
cat *.ova | tar -xvC "$TMP_DIR"
rm -f *.ova

VMDK="$(echo "$TMP_DIR"/*.vmdk)"

# Hack into a VMDK2 image (from https://github.com/erik-smit/one-liners/blob/master/qemu-img.vmdk3.hack.sh)
FULLSIZE=$(stat -c%s "$VMDK")
VMDKFOOTER=$(($FULLSIZE - 0x400))
VMDKFOOTERVER=$(($VMDKFOOTER  + 4))

case "`xxd -ps -s $VMDKFOOTERVER -l 1 \"$VMDK\"`" in
  03)
    echo "$VMDK is VMDK3, patching to VMDK2."
    /bin/echo -en '\x02' | dd conv=notrunc \
                              status=noxfer \
                              bs=1 \
                              seek="$VMDKFOOTERVER" \
                              of="$VMDK"
    ;;
  02)
    echo "Already a VMDK2 file"
    ;;
  default)
    echo "$VMDK is neither version 2 or 3"
    exit 1
  ;;
esac

# Convert into QCOW2
QCOW2="$(basename "$TMP_DIR"/*.ovf .ovf).qcow2"
qemu-img convert -f vmdk -O qcow2 "$VMDK" "$QCOW2"

# Remove now-useless files
rm "$VMDK" "$TMP_DIR"/*.ov[fa]

echo Finished! Deleting "$TMP_DIR" to tidy up
rmdir "$TMP_DIR" || true
ln -sf "$QCOW2" "disk.qcow2"
echo Run ./start.sh '"'"$QCOW2"'"' to start IE
