#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091
. .ci/common/platform.sh

ROOTDIR="$PWD"
BUILDDIR="$ROOTDIR/${BUILDDIR:-build}"
ARTIFACTS_DIR="$ROOTDIR/artifacts"

BINDIR="$BUILDDIR/bin"
PKGDIR="$BUILDDIR/pkg"
TMP_DIR=$(mktemp -d)
EXE="eden.exe"

WINDEPLOYQT="${WINDEPLOYQT:-windeployqt6}"

rm -f "$BINDIR/"*.pdb || true

mkdir -p "$ARTIFACTS_DIR"
[ -n "$PKGDIR" ] && rm -rf "$PKGDIR"
mkdir -p "$PKGDIR"

cp "$BINDIR/"*.exe "$PKGDIR"
cd "$PKGDIR"

# not needed anymore yay
# if [ "$PLATFORM" = "msys" ]; then
# 	echo "-- On MSYS, bundling MinGW DLLs..."

# 	MSYS_TOOLCHAIN="${MSYS_TOOLCHAIN:-$MSYSTEM}"
# 	export PATH="/${MSYS_TOOLCHAIN}/bin:$PATH"

# 	# grab deps of a dll or exe and place them in the current dir
# 	deps() {
# 		objdump -p "$1" | awk '/DLL Name:/ {print $3}' | while read -r dll; do
# 			[ -z "$dll" ] && continue

# 			dllpath=$(command -v "$dll" 2>/dev/null || true)

# 			[ -z "$dllpath" ] && continue

# 			case "$dllpath" in
# 				*System32* | *SysWOW64*) continue ;;
# 			esac

# 			if [ ! -f "$dll" ]; then
# 				echo "$dllpath"
# 				cp "$dllpath" "$dll"
# 				deps "$dllpath"
# 			fi
# 		done
# 	}

# 	deps "$EXE"
# fi

# qt
[ "$PLATFORM" != "msys" ] && ${WINDEPLOYQT} --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler "$EXE"

# if [ "$PLATFORM" = "msys" ]; then
# 	# grab deps for Qt plugins
# 	find ./*/ -name "*.dll" | while read -r dll; do deps "$dll"; done
# fi

# ?ploo
ZIP_NAME="Eden-Windows-${ARCH}.zip"

cp -r "$PKGDIR"/* "$TMP_DIR"/
cp -r "$ROOTDIR"/LICENSE* "$ROOTDIR"/README* "$TMP_DIR"/

7z a -tzip "$ARTIFACTS_DIR/$ZIP_NAME" "$TMP_DIR"/*

rm -rf "$TMP_DIR"
