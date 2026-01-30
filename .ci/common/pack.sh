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
		ARTIFACT="${PROJECT_PRETTYNAME}-Linux-${ARTIFACT_REF}-${arch}-${compiler}"

		cp "$ROOTDIR/linux-$arch-$compiler"/*.AppImage "$ARTIFACTS_DIR/$ARTIFACT.AppImage"
		tagged && cp "$ROOTDIR/linux-$arch-$compiler"/*.AppImage.zsync "$ARTIFACTS_DIR/$ARTIFACT.AppImage.zsync"
	done
done

## Debian ##
ARCHES=amd64
opts && tagged && ARCHES="$ARCHES aarch64"

for arch in $ARCHES; do
	for ver in 24.04; do
		cp "$ROOTDIR/ubuntu-$ver-$arch"/*.deb "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Ubuntu-$ver-${ARTIFACT_REF}-$arch.deb"
	done

	for ver in 12 13; do
		cp "$ROOTDIR/debian-$ver-$arch"/*.deb "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Debian-$ver-${ARTIFACT_REF}-$arch.deb"
	done
done

## Android ##
if falsy "$DISABLE_ANDROARTIFACT_REF"; then
	FLAVORS="standard chromeos"
	opts && tagged && FLAVORS="$FLAVORS legacy optimized"

	for flavor in $FLAVORS; do
		cp "$ROOTDIR/android-$flavor"/*.apk "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Android-${ARTIFACT_REF}-${flavor}.apk"
	done
fi

## Windows ##
COMPILERS="msvc-standard"

ARCHES=amd64
falsy "$DISABLE_MSVC_ARM" && ARCHES="$ARCHES arm64"

for arch in $ARCHES; do
	for compiler in $COMPILERS; do
		cp "$ROOTDIR/windows-$arch-$compiler"/*.zip "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Windows-${ARTIFACT_REF}-${arch}-${compiler}.zip"
	done
done

## MinGW ##
if falsy "$DISABLE_MINGW"; then
	COMPILERS="amd64-gcc-standard arm64-clang-standard"
	opts && tagged && COMPILERS="$COMPILERS amd64-clang-pgo arm64-clang-pgo"

	for compiler in $COMPILERS; do
		cp "$ROOTDIR/mingw-$compiler"/*.zip "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Windows-${ARTIFACT_REF}-mingw-${compiler}.zip"
	done
fi

## Source Pack ##
if [ -d "source" ]; then
	cp "$ROOTDIR/source/source.tar.zst" "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Source-${ARTIFACT_REF}.tar.zst"
fi

## MacOS ##
cp "$ROOTDIR/macos"/*.tar.gz "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-macOS-${ARTIFACT_REF}.tar.gz"

## FreeBSD and other stuff ##
cp "$ROOTDIR/freebsd-binary-amd64-clang"/*.tar.zst "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-FreeBSD-${ARTIFACT_REF}-amd64-clang.tar.zst"

## musl room ##
for arch in aarch64 x86_64; do
	cp room-$arch/* "$ARTIFACTS_DIR"
done

ls "$ARTIFACTS_DIR"
