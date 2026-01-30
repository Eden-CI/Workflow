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

find "$ROOTDIR" \( \
	    -name '*.deb' -o \
		-name '*.AppImage*' \
		-name '*.zip' \
    \) -exec cp {} "$ARTIFACTS_DIR" \;

## Android ##
if falsy "$DISABLE_ANDROARTIFACT_REF"; then
	FLAVORS="standard chromeos"
	opts && tagged && FLAVORS="$FLAVORS legacy optimized"

	for flavor in $FLAVORS; do
		cp "$ROOTDIR/android-$flavor"/*.apk "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-Android-${ARTIFACT_REF}-${flavor}.apk"
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

ls -lh "$ARTIFACTS_DIR"
