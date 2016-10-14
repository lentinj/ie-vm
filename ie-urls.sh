#!/bin/sh -e

cat <<EOF 1>&2
By downloading and using these VMs, you are agreeing Microsoft Software License
Terms. You should go to https://www.modern.ie and read them if you haven't
before

EOF

wget -q -O - https://developer.microsoft.com/en-us/microsoft-edge/api/tools/vms/ \
    | grep -oiE 'https://[A-Z0-9._/]+\.VirtualBox\.(txt|zip)' \
    | grep -v '/md5/' \
    | sort | uniq
