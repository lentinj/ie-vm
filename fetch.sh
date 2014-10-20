#!/bin/sh -e

[ -z "$1" ] && { echo "Usage: $0 [url to IE.txt file]"; exit 1; }

TMP_DIR=./ie-vm-fetch-workdir

# Fetch constituent parts
wget -q -O - "$1" | dos2unix | xargs -n1 -P8 wget -c -P "$TMP_DIR"

exec ./convert.sh $TMP_DIR
