#!/bin/sh -e

cat <<EOF 1>&2
By downloading and using these VMs, you are agreeing Microsoft Software License
Terms. You should go to https://www.modern.ie and read them if you haven't
before

EOF

curl -s https://www.modern.ie/en-gb/virtualization-tools \
    | grep -oiE 'https://[A-Z0-9._/]+For\.Linux\.VirtualBox\.txt' \
    | sort | uniq
