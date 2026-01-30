#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC2043

ROOTDIR="$PWD"
ARTIFACTS_DIR="artifacts"

# shellcheck disable=SC1091
. "$ROOTDIR"/.ci/common/project.sh

mkdir -p "$ARTIFACTS_DIR"

ls "$ROOTDIR"

find "$ROOTDIR" \( \
	    -name '*.deb' -o \
		-name '*.AppImage*' -o \
		-name '*.zip' -o \
		-name '*.exe' -o \
		-name '*.tar.zst' -o \
		-name '*.apk' -o \
		-name '*.tar.gz' -o \
		-name '*unknown-linux-musl*' \
    \) -exec cp {} "$ARTIFACTS_DIR" \;

ls -lh "$ARTIFACTS_DIR"
