#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later
ROOTDIR="$PWD"
BUILDDIR="$ROOTDIR/makedeb"
DIR=$0; [ -n "${BASH_VERSION-}" ] && DIR="${BASH_SOURCE[0]}"; WORKFLOW_DIR="$(cd "$(dirname -- "$DIR")/../.." && pwd)"

# Use sudo if available, otherwise run directly
SUDO=; command -v sudo >/dev/null 2>&1 && SUDO=sudo
OPTS=; [ -n "${CI:-}" ] && OPTS='-y'

if command -v apt >/dev/null 2>&1 ; then
	$SUDO apt update
	$SUDO apt install $OPTS git asciidoctor binutils build-essential curl fakeroot file \
		gettext gawk libarchive-tools lsb-release python3 python3-apt zstd mold
fi

# install makedeb
echo "-- Installing makedeb..."
[ ! -d makedeb-src ] && git clone 'https://github.com/makedeb/makedeb' "$BUILDDIR"
cd $BUILDDIR
git checkout stable

make prepare VERSION=16.0.0 RELEASE=stable TARGET=apt CURRENT_VERSION=16.0.0 FILESYSTEM_PREFIX="$BUILDDIR/makedeb"
make
make package DESTDIR="$BUILDDIR/makedeb" TARGET=apt

if [ -n "${CI:-}" ]; then
    echo "$BUILDDIR/makedeb/usr/bin" >> "$GITHUB_PATH"
fi
export PATH="$BUILDDIR/makedeb/usr/bin:$PATH"
makedeb --help
