#!/bin/bash

whoami

echo $UID $EUID

sudo strace -p 20199 -tt -qq -f -e read 2>&1

# awk '$2 ~ /read/ { print substr($3, 1, length($3) - 1) }'
