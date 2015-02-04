#!/bin/sh -e

curl -s https://www.modern.ie/en-gb/virtualization-tools \
    | grep -oiE 'https://[A-Z0-9._/]+For\.Linux\.VirtualBox\.txt' \
    | sort | uniq
