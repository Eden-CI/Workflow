#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC2043

ROOTDIR="$PWD"
ARTIFACTS_DIR="$ROOTDIR/artifacts"

# shellcheck disable=SC1091
. "$ROOTDIR/.ci/common/project.sh"

mkdir -p "$ARTIFACTS_DIR"

rm -f eden.zip

find "$ROOTDIR" \( \
	    -name '*.deb' -o \
		-name '*.AppImage*' -o \
		-name '*.zip' -o \
		-name '*.exe' -o \
		-name '*.tar.zst' -o \
		-name '*.apk' -o \
		-name '*.tar.gz' -o \
		-name '*unknown-linux-musl*' \
    \) -not -path "*artifacts*" -exec cp {} "$ARTIFACTS_DIR" \;

if [ "$DEVEL" = false ]; then
	sudo apt-get install -y mktorrent
	_dir="${PROJECT_PRETTYNAME}-${ARTIFACT_REF}"
	ln -s "$ARTIFACTS_DIR" "${_dir}"
	mktorrent -p -a udp://tracker.opentrackr.org:1337/announce -o "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-${ARTIFACT_REF}.torrent" "${_dir}/"
fi

ls -lh "$ARTIFACTS_DIR"
