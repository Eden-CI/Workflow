#!/bin/sh -ex

MANDB=/var/lib/man-db/auto-update

[ -f $MANDB ] && sudo rm $MANDB

[ ! -d makedeb ] && git clone 'https://github.com/makedeb/makedeb' makedeb-src
cd makedeb-src
git checkout stable

sudo apt install -y asciidoctor binutils build-essential curl fakeroot file \
	gettext gawk libarchive-tools lsb-release python3 python3-apt zstd

make prepare VERSION=16.0.0 RELEASE=stable TARGET=apt CURRENT_VERSION=16.0.0 FILESYSTEM_PREFIX="$PWD/makedeb"
make
make package DESTDIR="$PWD/makedeb" TARGET=apt
mv makedeb ..

cd ..

[ -n "$GITHUB_PATH" ] && echo "$PWD/makedeb/usr/bin" >> "$GITHUB_PATH"