#!/bin/sh -e

cat <<EOF 1>&2
By downloading and using these VMs, you are agreeing Microsoft Software License
Terms. You should go to https://www.modern.ie and read them if you haven't
before

EOF

wget -q -O - https://dev.windows.com/en-us/microsoft-edge/tools/vms/linux/ \
    | grep -oiE 'https://[A-Z0-9._/]+For\.[A-Z0-9._/]+\.VirtualBox\.txt' \
    | sort | uniq
