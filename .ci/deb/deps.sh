#!/bin/bash

export TERM=dumb

set -x
wget -qO install.sh 'https://shlink.makedeb.org/install'
chmod +x install.sh
./install.sh
rm install.sh

makedeb --help || { echo 'makedeb failed to install' ; exit 1; }