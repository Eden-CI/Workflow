#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC2043

ROOTDIR="$PWD"
ARTIFACTS_DIR="artifacts"

# shellcheck disable=SC1091
. "$ROOTDIR"/.ci/common/project.sh

mkdir -p "$ARTIFACTS_DIR"

tagged() {
	falsy "$DEVEL"
}

opts() {
	falsy "$DISABLE_OPTS"
}

## AppImage ##
ARCHES="amd64"
opts && ARCHES="$ARCHES steamdeck"
[ "$DISABLE_ARM" != "true" ] && ARCHES="$ARCHES aarch64"
COMPILERS=gcc-standard

opts && tagged && ARCHES="$ARCHES legacy rog-ally" && COMPILERS="$COMPILERS clang-pgo"

for arch in $ARCHES; do
	for compiler in $COMPILERS; do
		ARTIFACT="${PROJECT_PRETTYNAME}-Linux-${ID}-${arch}-${compiler}"

		cp "$ROOTDIR/linux-$arch-$compiler"/*.AppImage "$ARTIFACTS_DIR/$ARTIFACT.AppImage"
		tagged && cp "$ROOTDIR/linux-$arch-$compiler"/*.AppImage.zsync "$ARTIFACTS_DIR/$ARTIFACT.AppImage.zsync"
	done
done

## Debian ##
ARCHES=amd64
opts && tagged && ARCHES="$ARCHES aarch64"

for arch in $ARCHES; do
	for ver in 24.04; do
		cp "$ROOTDIR/ubuntu-$ver-$arch"/*.deb "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Ubuntu-$ver-${ID}-$arch.deb"
	done

	for ver in 12 13; do
		cp "$ROOTDIR/debian-$ver-$arch"/*.deb "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Debian-$ver-${ID}-$arch.deb"
	done
done

## Android ##
if falsy "$DISABLE_ANDROID"; then
	FLAVORS=standard
	opts && tagged && FLAVORS="$FLAVORS legacy optimized"

	for flavor in $FLAVORS; do
		cp "$ROOTDIR/android-$flavor"/*.apk "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Android-${ID}-${flavor}.apk"
	done
fi

## Windows ##
COMPILERS="msvc-standard"
opts && tagged && COMPILERS="$COMPILERS clang-pgo"

ARCHES=amd64
falsy "$DISABLE_MSVC_ARM" && ARCHES="$ARCHES arm64"

for arch in $ARCHES; do
	for compiler in $COMPILERS; do
		cp "$ROOTDIR/windows-$arch-$compiler"/*.zip "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Windows-${ID}-${arch}-${compiler}.zip"
	done
done

## MinGW ##
if falsy "$DISABLE_MINGW"; then
	COMPILERS="amd64-gcc-standard arm64-clang-standard"
	opts && tagged && COMPILERS="$COMPILERS amd64-clang-pgo arm64-clang-pgo"

	for compiler in $COMPILERS; do
		cp "$ROOTDIR/mingw-$compiler"/*.zip "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Windows-${ID}-mingw-${compiler}.zip"
	done
fi

## Source Pack ##
if [ -d "source" ]; then
	cp "$ROOTDIR/source/source.tar.zst" "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Source-${ID}.tar.zst"
fi

## MacOS ##
cp "$ROOTDIR/macos"/*.tar.gz "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-macOS-${ID}.tar.gz"

## FreeBSD and other stuff ##
cp "$ROOTDIR/freebsd-binary-amd64-clang"/*.tar.zst "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-FreeBSD-${ID}-amd64-clang.tar.zst"

ls "$ARTIFACTS_DIR"
