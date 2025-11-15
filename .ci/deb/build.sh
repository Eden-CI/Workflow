#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

export ROOTDIR="$PWD"
WORKFLOW_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

GITHUB_WORKSPACE="$ROOTDIR"

# install makedeb
echo "-- Installing makedeb..."
[ ! -d makedeb-src ] && git clone 'https://github.com/makedeb/makedeb' makedeb-src
cd makedeb-src
git checkout stable

make prepare VERSION=16.0.0 RELEASE=stable TARGET=apt CURRENT_VERSION=16.0.0 FILESYSTEM_PREFIX="$ROOTDIR/makedeb"
make
make package DESTDIR="$ROOTDIR/makedeb" TARGET=apt

export PATH="$ROOTDIR/makedeb/usr/bin:$PATH"

# now build
echo "-- Building..."
cd "$ROOTDIR"

SRC="$WORKFLOW_DIR/.ci/deb/PKGBUILD.in"
DEST=PKGBUILD

TAG=$(cat "$GITHUB_WORKSPACE"/GIT-TAG | sed 's/.git//' | sed 's/v//' | sed 's/[-_]/./g' | tr -d '\n')
if [ -f "$GITHUB_WORKSPACE"/GIT-RELEASE ]; then
	PKGVER="$TAG"
else
	REF=$(cat "$GITHUB_WORKSPACE"/GIT-COMMIT)
	PKGVER="$TAG.$REF"
fi

sed "s/%PKGVER%/$PKGVER/" "$SRC"  > $DEST.1
sed "s/%ARCH%/$ARCH/"     $DEST.1 > $DEST

rm $DEST.*

if ! command -v sudo >/dev/null 2>&1 ; then
	alias sudo="su - root -c"
fi

makedeb --print-srcinfo > .SRCINFO
makedeb -s --no-confirm

# for some grand reason, makepkg does not exit on errors
ls eden*.deb || exit 1
