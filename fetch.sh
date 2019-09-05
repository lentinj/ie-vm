#!/bin/sh -e

VMDK2_PATCH=""
URL=""

# support more options
# modified version of https://gist.github.com/adamhotep/895cebf290e95e613c006afbffef09d7
usage() {
    cat <<EOF
    usage: $0 [--vmdk2] (url to IE.txt  / .zip file)

    --vmdk2                Hack VMDK image into a v2 image, not required by qemu-img 1.7.0+
    (url)                  URL for downloading image, as produced by ie-urls.sh
EOF
    exit
}

reset=true
for arg in "$@"
do
    if [ -n "$reset" ]; then
      unset reset
      set --      # this resets the "$@" array so we can rebuild it
    fi
    case "$arg" in
       --help)    set -- "$@" -h ;;
       --vmdk2)   set -- "$@" -v ;;
       # pass through anything else
       *)         set -- "$@" "$arg" ;;
    esac
done
# now we can process with getopt
while getopts ":hv" opt; do
    case $opt in
        h)  usage ;;
        v) VMDK2_PATCH="1" ;;
        \?) usage ;;
        :)
        echo "option -$OPTARG requires an argument"
        usage
        ;;
    esac
done
shift $((OPTIND-1))

# Use positional argument as URL
[ -n "$1" ] && { URL="$1"; shift; }
[ -z "${URL}" ] && { echo "Usage: $0 [url to IE.txt  / .zip file]"; exit 1; }

# Fetch files required
if echo "${URL}" | grep -qE '\.zip$'; then
    # Fetch ZIP file
    TMP_DIR="./workdir-$(basename "${URL}" .zip | sed 's/%20/ /')"
    wget -c -P "$TMP_DIR" "${URL}"
else
    # Fetch each part of zip file
    TMP_DIR="./workdir-$(basename "${URL}" .txt)"
    wget -q -O - "${URL}" | tr -d "\r" | xargs -n1 -P8 wget -c -P "$TMP_DIR"
fi

# Extract VMDK from archive
cat "$TMP_DIR"/*.zip* | funzip | tar -xvC "$TMP_DIR"
VMDK="$(echo "$TMP_DIR"/*.vmdk)"
[ -e "$VMDK" ] || { echo "No VMDK extracted" 1>&2; exit 1; }

if [ -n "${VMDK2_PATCH}" ]; then
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
fi

# Convert into QCOW2
QCOW2="$(basename "$TMP_DIR"/*.ovf .ovf).qcow2"
qemu-img convert -f vmdk -O qcow2 "$VMDK" "$QCOW2"

# Remove now-useless files
rm "$VMDK" "$TMP_DIR"/*.ovf

echo Finished! Delete "$TMP_DIR" to tidy up
echo Run ./start.sh '"'"$QCOW2"'"' to start IE
