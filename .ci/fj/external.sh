#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091

ROOTDIR="$PWD"
. "$ROOTDIR/.ci/common/project.sh"

FJ_HOST="$RELEASE_HOST"
FJ_REPO="$RELEASE_REPO"

sed -i "s|$RELEASE_HOST/$RELEASE_REPO/releases/download|$B2_BUCKET.$B2_URL/$B2_DIR|g" "$ROOTDIR/changelog.md"
git clone --depth 1 https://git.crueter.xyz/scripts/fj.git

echo "-- Creating Release"
"$ROOTDIR/fj/fj.sh" -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$FORGEJO_REF" \
	create -b "$ROOTDIR/changelog.md" -n "$PROJECT_PRETTYNAME $FORGEJO_REF"

echo "-- Uploading Assets"

# shellcheck disable=SC2046

"$ROOTDIR/fj/fj.sh" -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$FORGEJO_REF" \
	external $(cat "$ROOTDIR"/urls.txt)

export FJ_URL="https://$FJ_HOST/$FJ_REPO/releases/tag/$FORGEJO_REF"
