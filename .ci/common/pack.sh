#!/bin/sh

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC2043

mkdir -p artifacts

tagged() {
	[ "$DEVEL" != "true" ]
}

## AppImage ##
ARCHES="amd64 steamdeck"
[ "$DISABLE_ARM" != "true" ] && ARCHES="$ARCHES aarch64"
COMPILERS=gcc-standard

tagged && ARCHES="$ARCHES legacy rog-ally" && COMPILERS="$COMPILERS clang-pgo"

for arch in $ARCHES; do
	for compiler in $COMPILERS; do
		ARTIFACT="Eden-Linux-${ID}-${arch}-${compiler}"

		cp "linux-$arch-$compiler"/*.AppImage "artifacts/$ARTIFACT.AppImage"
		tagged && cp "linux-$arch-$compiler-standard"/*.AppImage.zsync "artifacts/$ARTIFACT.AppImage.zsync"
	done
done

## Debian ##
ARCHES=amd64
tagged && ARCHES="$ARCHES aarch64"

for arch in $ARCHES; do
	for ver in 24.04; do
		cp "ubuntu-$ver-$arch"/*.deb "artifacts/Eden-Ubuntu-$ver-${ID}-$arch.deb"
	done

	for ver in 12 13; do
		cp "debian-$ver-$arch"/*.deb "artifacts/Eden-Debian-$ver-${ID}-$arch.deb"
	done
done

## Android ##
FLAVORS=standard
tagged && FLAVORS="$FLAVORS legacy optimized"

for flavor in $FLAVORS; do
	cp android-"$flavor"/*.apk "artifacts/Eden-Android-${ID}-${flavor}.apk"
done

## Windows ##
COMPILERS="msvc-standard"
tagged && COMPILERS="$COMPILERS clang-pgo"

for arch in amd64 arm64; do
	for compiler in $COMPILERS; do
		cp "windows-$arch-compiler"/*.zip "artifacts/Eden-Windows-${ID}-${arch}-${compiler}.zip"
	done
done

## MinGW ##
COMPILERS="gcc-standard"
tagged && COMPILERS="$COMPILERS clang-pgo"

for arch in amd64; do
	for compiler in $COMPILERS; do
		cp "mingw-$arch-$compiler"/*.zip "artifacts/Eden-Windows-${ID}-${arch}-mingw-${compiler}.zip"
	done
done

## Source Pack ##
if [ -d "source" ]; then
	cp source/source.tar.zst "artifacts/Eden-Source-${ID}.tar.zst"
fi

## MacOS ##
cp macos/*.tar.gz "artifacts/Eden-macOS-${ID}.tar.gz"

## FreeBSD and other stuff ##
cp freebsd-binary-amd64-clang/*.tar.zst "artifacts/Eden-FreeBSD-${ID}-amd64-clang.tar.zst"

ls artifacts