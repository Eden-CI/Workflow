#!/bin/sh -x

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

mkdir -p artifacts

ARCHES="amd64 steamdeck"

[ "$DISABLE_ARM" != "true" ] && ARCHES="$ARCHES aarch64"
COMPILERS="gcc"
if [ "$DEVEL" = "false" ]; then
	ARCHES="$ARCHES legacy rog-ally"
	COMPILERS="$COMPILERS clang"
fi

for arch in $ARCHES; do
	for compiler in $COMPILERS; do
		ARTIFACT="Eden-Linux-${ID}-${arch}-${compiler}-standard"

		cp "linux-$arch-$compiler-standard"/*.AppImage "artifacts/$ARTIFACT.AppImage"
		if [ "$DEVEL" = "false" ]; then
			cp "linux-$arch-$compiler-standard"/*.AppImage.zsync "artifacts/$ARTIFACT.AppImage.zsync"
		fi
	done

	if [ "$DEVEL" != "true" ]; then
		ARTIFACT="Eden-Linux-${ID}-${arch}-clang-pgo"

		cp "linux-$arch-clang-pgo"/*.AppImage.zsync "artifacts/$ARTIFACT.AppImage.zsync"
		cp "linux-$arch-clang-pgo"/*.AppImage "artifacts/$ARTIFACT.AppImage"
	fi
done

FLAVORS=standard
if [ "$DEVEL" = "false" ]; then
	FLAVORS="standard legacy optimized"
fi

for flavor in $FLAVORS; do
	cp android-"$flavor"/*.apk "artifacts/Eden-Android-${ID}-${flavor}.apk"
done

for arch in amd64 arm64; do
	for compiler in clang msvc; do
		cp "windows-$arch-${compiler}-standard"/*.zip "artifacts/Eden-Windows-${ID}-${arch}-${compiler}-standard.zip"
	done

	if [ "$DEVEL" != "true" ]; then
		cp "windows-$arch-clang-pgo"/*.zip "artifacts/Eden-Windows-${ID}-${arch}-clang-pgo.zip"
	fi
done

if [ -d "source" ]; then
	cp source/source.tar.zst "artifacts/Eden-Source-${ID}.tar.zst"
fi

cp -r macos/*.tar.gz "artifacts/Eden-macOS-${ID}.tar.gz"

# TODO
cp -r freebsd-binary-amd64-clang/*.tar.zst "artifacts/Eden-FreeBSD-${ID}-amd64-clang.tar.zst"


for arch in aarch64 amd64; do
	for ver in "Ubuntu-24.04" "Debian-12" "Debian-13"; do
		pkg_ver=$(echo "$ver" | tr '[:upper:]' '[:lower:]')
		cp "$pkg_ver-$arch"/eden_*.deb "artifacts/Eden-$ver-${ID}-$arch.deb"
	done
done
