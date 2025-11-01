#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091
. .ci/common/platform.sh

BUILDDIR="${BUILDDIR:-build}"
WINDEPLOYQT="${WINDEPLOYQT:-windeployqt6}"

set +e
rm -f "${BUILDDIR}/bin/"*.pdb
set -e

"${WINDEPLOYQT}" --release --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler --dir "${BUILDDIR}/pkg" "${BUILDDIR}/bin/eden.exe"
cp "${BUILDDIR}/bin/"* "${BUILDDIR}/pkg"

if [ "$PLATFORM" = "msys" ]; then
	# TODO: variable?
	curl -o bundle https://github.com/eden-emulator/mingw-bundledlls/raw/refs/heads/master/mingw-bundledlls
	chmod a+x bundle
	./bundle --copy "${BUILDDIR}/pkg/eden.exe"
fi

GITDATE=$(git show -s --date=short --format='%ad' | tr -d "-")
GITREV=$(git show -s --format='%h')

ZIP_NAME="Eden-Windows-${ARCH}-${GITDATE}-${GITREV}.zip"

ARTIFACTS_DIR="artifacts"
PKG_DIR="${BUILDDIR}/pkg"

mkdir -p "$ARTIFACTS_DIR"

TMP_DIR=$(mktemp -d)

cp -r "$PKG_DIR"/* "$TMP_DIR"/
cp -r LICENSE* README* "$TMP_DIR"/

7z a -tzip "$ARTIFACTS_DIR/$ZIP_NAME" "$TMP_DIR"/*

rm -rf "$TMP_DIR"
