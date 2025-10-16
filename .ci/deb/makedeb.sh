#!/bin/sh -ex

[ ! -d makedeb ] && git clone 'https://github.com/makedeb/makedeb' makedeb-src
cd makedeb-src
git checkout stable

sudo apt install -y binutils build-essential curl fakeroot file \
	gettext gawk libarchive-tools lsb-release python3 python3-apt zstd

make prepare VERSION=16.0.0 RELEASE=stable TARGET=apt CURRENT_VERSION=16.0.0
make
make package DESTDIR="$PWD/makedeb" TARGET=apt
mv makedeb ..

cd ..

[ -n "$GITHUB_PATH" ] && echo "$PWD/makedeb" >> "$GITHUB_PATH"