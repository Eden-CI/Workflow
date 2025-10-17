#!/bin/sh -ex

MANDB=/var/lib/man-db/auto-update

ROOTDIR="$PWD"

[ -f $MANDB ] && sudo rm $MANDB

[ ! -d makedeb-src ] && git clone 'https://github.com/makedeb/makedeb' makedeb-src
cd makedeb-src
git checkout stable

if command -v apt > /dev/null; then
	sudo apt update
	sudo apt install -y asciidoctor binutils build-essential curl fakeroot file \
		gettext gawk libarchive-tools lsb-release python3 python3-apt zstd
fi

make prepare VERSION=16.0.0 RELEASE=stable TARGET=apt CURRENT_VERSION=16.0.0 FILESYSTEM_PREFIX="$ROOTDIR/makedeb"
make
make package DESTDIR="$ROOTDIR/makedeb" TARGET=apt

[ -n "$GITHUB_PATH" ] && echo "$ROOTDIR/makedeb/usr/bin" >> "$GITHUB_PATH"