#!/bin/sh -e

[ -z "$1" ] && { echo "Usage: $0 [url to IE.txt file]"; exit 1; }

TMP_DIR=./ie-vm-fetch-workdir

# Fetch constituent parts
for url in $(curl -s "$1" | dos2unix); do
    (cd $TMP_DIR && curl -C - -O $url; ) &
done
wait

exec ./convert.sh $TMP_DIR
