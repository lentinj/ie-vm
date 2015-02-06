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

if [ ! -e virtio*.iso ]; then
    # Grab the virtio driver ISO at build time (http://www.linux-kvm.org/page/WindowsGuestDrivers/Download_Drivers)
    echo Fetching virtIO drivers...
    wget -c --recursive --no-directories --accept-regex 'virtio.*\.iso' \
        http://alt.fedoraproject.org/pub/alt/virtio-win/stable/

    # If we hav xorriso, extract the iso to a shared/ folder
    if [ -x xorriso ]; then
        mkdir -p shared/
        xorriso -indev virtio-win-0.1-81.iso -osirrox "on" -extract / shared/
	# Horribly lowercase the 3 nested directories of shared/ - linux filesystems are case sensitive by default
        find shared/ -exec rename "y/A-Z/a-z/" {} \; || \
        find shared/ -exec rename "y/A-Z/a-z/" {} \; || \
        find shared/ -exec rename "y/A-Z/a-z/" {} \;
    fi
fi

#  Grab the windows SPICE guest tools (includes the drivers grabbed separately below)
[ -e shared/spice-guest-tools-0.74.exe ] || \
  ( cd shared ; wget http://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-0.74.exe )

# Grab the windows vdagent service executables (included in the spice-guest-tools)
if [ ! -e mingw64-spice-vdagent-*rpm ]; then
 wget http://www.spice-space.org/download/windows/vdagent/vdagent-win-0.7.2/mingw64-spice-vdagent-0.7.2-1.fc19.noarch.rpm
 if [ ! -d shared/sys-root/ ]; then
   if which alien > /dev/null ; then
     alien mingw64-spice-vdagent-0.7.2-1.fc19.noarch.rpm
     if which dpkg > /dev/null ; then
       dpkg -i mingw64*deb && true
       dpkg --listfiles mingw64-spice-vdagent
       cp -a /usr/x86_64-w64-mingw32/sys-root shared/sys-root/
     fi
   fi
 fi
fi

# Grab the windows SPICE qxl video drivers (also included in the spice-guest-tools)
for guestver in 8kR6_x64 w7_x64 w7_x86 xp_x86 ; do
  [ -f qxl_${image}.zip ] || wget http://www.spice-space.org/download/windows/qxl/qxl-0.1-21/qxl_${guestver}.zip && \
    ( cd shared; unzip -L ../qxl_${guestver}.zip )
done

# NOTE: All of the above really needs to be slipstreamed with DISM.exe in WAIK included in Windows7+

echo Run ./start.sh '"'"$QCOW2"'"' to start IE
