#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091
. .ci/common/platform.sh

ROOTDIR="$PWD"

BUILDDIR="${BUILDDIR:-$ROOTDIR/build}"
BINDIR="${BUILDDIR}/bin"

PKGDIR="${BUILDDIR}/pkg"
EXE="eden.exe"

WINDEPLOYQT="${WINDEPLOYQT:-windeployqt6}"

rm -f "${BINDIR}/"*.pdb || true

mkdir -p "$PKGDIR"

cp "${BINDIR}/"*.exe "$PKGDIR"
cd "$PKGDIR"

if [ "$PLATFORM" = "msys" ]; then
	echo "-- On MSYS, bundling MinGW DLLs..."

	MSYS_TOOLCHAIN="${MSYS_TOOLCHAIN:-$MSYSTEM}"
	export PATH="/${MSYS_TOOLCHAIN}/bin:$PATH"

	# grab deps of a dll or exe and place them in the current dir
	deps() {
		objdump -p "$1" | grep -e ".DLL Name:" | cut -d" " -f3 | while read -r dll; do
			[ -z "$dll" ] && continue

			dllpath=$(command -v "$dll" 2>/dev/null || true)

			[ -z "$dllpath" ] && continue

			case "$dllpath" in
				*System32* | *SysWOW64*) continue ;;
			esac

			if [ ! -f "$dll" ]; then
				echo "$dllpath"
				cp "$dllpath" "$dll"
				deps "$dllpath"
			fi
		done
	}

	deps "$EXE"
fi

# qt
${WINDEPLOYQT} --release --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler "$EXE"

if [ "$PLATFORM" = "msys" ]; then
	# grab deps for Qt plugins
	find ./*/ -name "*.dll" | while read -r dll; do deps "$dll"; done
fi

# ?ploo
ZIP_NAME="Eden-Windows-${ARCH}.zip"

ARTIFACTS_DIR="$ROOTDIR/artifacts"

mkdir -p "$ARTIFACTS_DIR"

TMP_DIR=$(mktemp -d)

cp -r "$PKGDIR"/* "$TMP_DIR"/
cp -r LICENSE* README* "$TMP_DIR"/

7z a -tzip "$ARTIFACTS_DIR/$ZIP_NAME" "$TMP_DIR"/*

rm -rf "$TMP_DIR"
