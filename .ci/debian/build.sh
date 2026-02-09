#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

ROOTDIR="$PWD"
BUILDDIR="${BUILDDIR:-$ROOTDIR/build}"
ARTIFACTS_DIR="$ROOTDIR/artifacts"

# shellcheck disable=SC1091
WORKFLOW_DIR=$(CDPATH='' cd -P -- "$(dirname -- "$0")/../.." && pwd)
. "$WORKFLOW_DIR/.ci/common/project.sh"

if ! command -v makedeb > /dev/null 2>&1 ; then
	# install makedeb
	echo "-- Installing makedeb..."
	[ ! -d "$ROOTDIR/makedeb-src" ] && git clone 'https://github.com/makedeb/makedeb' "$ROOTDIR/makedeb-src"
	cd "$ROOTDIR/makedeb-src"
	git checkout stable

	make prepare VERSION=16.0.0 RELEASE=stable TARGET=apt CURRENT_VERSION=16.0.0 FILESYSTEM_PREFIX="$ROOTDIR/makedeb"
	make
	make package DESTDIR="$ROOTDIR/makedeb" TARGET=apt

	export PATH="$ROOTDIR/makedeb/usr/bin:$PATH"
fi

# now build
echo "-- Building..."
cd "$ROOTDIR"

CONFIG_OPTS=""
if [ -n "${SCCACHE_PATH-}" ] && [ -e "$SCCACHE_PATH" ]; then
    CONFIG_OPTS=" -DCCACHE_PATH=\"${SCCACHE_PATH}\""
fi

SRC="$WORKFLOW_DIR/.ci/debian/PKGBUILD.in"
DEST="$ROOTDIR/PKGBUILD"

TAG=$(cat "$ROOTDIR"/GIT-TAG | sed 's/.git//' | sed 's/v//' | sed 's/[-_]/./g' | tr -d '\n')
if [ -f "$ROOTDIR"/GIT-RELEASE ]; then
	PKGVER="$TAG"
else
	REF=$(cat "$ROOTDIR"/GIT-COMMIT)
	PKGVER="$TAG.$REF"
fi

sed "s|%PKGVER%|$PKGVER|"             "$SRC"    > "$DEST.1"
sed "s|%TARGET%|$TARGET|"             "$DEST.1" > "$DEST.2"
sed "s|%WORKFLOWDIR%|$WORKFLOW_DIR/|" "$DEST.2" > "$DEST.3"
sed "s|%BUILDDIR%|$BUILDDIR|"         "$DEST.3" > "$DEST.4"
sed "s|%CONFIG_OPTS%|$CONFIG_OPTS|"   "$DEST.4" > "$DEST.5"
sed "s|%COMPILER%|$COMPILER|"         "$DEST.5" > "$DEST.6"
sed "s|%SOURCE%|$ROOTDIR|"            "$DEST.6" > "$DEST"

rm $DEST.*

if ! command -v sudo >/dev/null 2>&1 ; then
	alias sudo="su - root -c"
fi

makedeb --print-srcinfo > "$ROOTDIR/.SRCINFO"
makedeb -s --no-confirm

: "${FULL_TARGET:=$TARGET}"
PACKAGE_TARGET="${PROJECT_PRETTYNAME}-${DEB_NAME}-${ARTIFACT_REF}-${FULL_TARGET}.deb"

# for some grand reason, makepkg does not exit on errors
ls ./*.deb || exit 1
mkdir -p "$ARTIFACTS_DIR"
mv ./*.deb "$ARTIFACTS_DIR/${PACKAGE_TARGET}"
