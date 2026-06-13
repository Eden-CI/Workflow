#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC2043

ROOTDIR="$PWD"
ARTIFACTS_DIR="$ROOTDIR/artifacts"

# shellcheck disable=SC1091
. "$ROOTDIR/.ci/build/project.sh"

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
		-name '*unknown-linux-musl*' -o \
		-name '*.dmg' \
    \) -not -path "*artifacts*" -exec cp {} "$ARTIFACTS_DIR" \;

if [ "$DEVEL" = false ]; then
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get install -y mktorrent
	fi
	files_dir="${PROJECT_PRETTYNAME}-${GITHUB_TAG}"
	ln -sf "$ARTIFACTS_DIR" "${files_dir}"
	mktorrent -pv \
		-a udp://tracker.opentrackr.org:1337/announce \
		-w "https://$B2_PUBLIC_URL/" \
		-o "$ARTIFACTS_DIR/${PROJECT_PRETTYNAME}-${ARTIFACT_REF}.torrent" \
		-n "${GITHUB_TAG}" \
		-l 20 \
		"${files_dir}/"
fi

ls -lh "$ARTIFACTS_DIR"
