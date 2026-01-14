#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

ROOTDIR="$PWD"
BUILDDIR="${BUILDDIR:-build}"
ARTIFACTS_DIR="$ROOTDIR/artifacts"
WORKFLOW_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck disable=SC1091
. "$ROOTDIR"/.ci/common/project.sh

BINDIR="$BUILDDIR/bin"
PKGDIR="$BUILDDIR/pkg"
TMP_DIR=$(mktemp -d)
EXE="${PROJECT_REPO}.exe"

WINDEPLOYQT="${WINDEPLOYQT:-windeployqt6}"

# check if common script folder is on Workflow
if [ ! -d "$WORKFLOW_DIR/.ci/common" ]; then
	echo "error: could not find .ci/common in Workflow at $WORKFLOW_DIR"
	exit 1
fi

# shellcheck disable=SC1091
. "$WORKFLOW_DIR"/.ci/common/platform.sh

rm -f "$BINDIR/"*.pdb || true

mkdir -p "$ARTIFACTS_DIR"
[ -n "$PKGDIR" ] && rm -rf "$PKGDIR"
mkdir -p "$PKGDIR"

cp "$BINDIR/"*.exe "$PKGDIR"
cd "$PKGDIR"

if [ "$PLATFORM" = "msys" ] && [ "$STATIC" != "ON" ]; then
	echo "-- On MSYS, bundling MinGW DLLs..."

	MSYS_TOOLCHAIN="${MSYS_TOOLCHAIN:-$MSYSTEM}"
	export PATH="/${MSYS_TOOLCHAIN}/bin:$PATH"

	# grab deps of a dll or exe and place them in the current dir
	deps() {
		objdump -p "$1" | awk '/DLL Name:/ {print $3}' | while read -r dll; do
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
if [ "$STATIC" != "ON" ]; then
	${WINDEPLOYQT} --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler "$EXE"
fi

if [ "$PLATFORM" = "msys" ] && [ "$STATIC" != "ON" ]; then
	# grab deps for Qt plugins
	find ./*/ -name "*.dll" | while read -r dll; do deps "$dll"; done
fi

# ?ploo
ZIP_NAME="${PROJECT_PRETTYNAME}-Windows-${ARCH}.zip"

cp -r ./* "$TMP_DIR"/
cp -r "$ROOTDIR"/LICENSE* "$ROOTDIR"/README* "$TMP_DIR"/

7z a -tzip "$ARTIFACTS_DIR/$ZIP_NAME" "$TMP_DIR"/*

rm -rf "$TMP_DIR"
