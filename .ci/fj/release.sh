#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091

ROOTDIR="$PWD"
DIR=$0; [ -n "${BASH_VERSION-}" ] && DIR="${BASH_SOURCE[0]}"; WORKFLOW_DIR="$(cd "$(dirname -- "$DIR")/../.." && pwd)"
. "$WORKFLOW_DIR/.ci/common/project.sh"
ARTIFACTS_DIR="$ROOTDIR/artifacts"

DEFAULT_JSON=".ci/default.json"
FJ_HOST=$(jq -r ".[0].host" $DEFAULT_JSON)
FJ_REPO=$(jq -r ".[0].repository" $DEFAULT_JSON)

sed -i "s|$RELEASE_HOST/$RELEASE_REPO|$FJ_HOST/$FJ_REPO|g" "$ROOTDIR/changelog.md"
git clone --depth 1 https://git.crueter.xyz/scripts/fj.git

echo "-- Creating Release"
"$WORKFLOW_DIR/fj/fj.sh" -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$FORGEJO_REF" \
	create -b "$ROOTDIR/changelog.md" -n "$PROJECT_PRETTYNAME $FORGEJO_REF" -d

echo "-- Uploading Assets"

# Cloudflare sucks, so we upload twice just to ensure we don't get blocked.
"$WORKFLOW_DIR/fj/fj.sh" -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$FORGEJO_REF" \
	upload -g "$ARTIFACTS_DIR"/*

"$WORKFLOW_DIR/fj/fj.sh" -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$FORGEJO_REF" \
	upload -g "$ARTIFACTS_DIR"/*

export FJ_URL="https://$FJ_HOST/$FJ_REPO/releases/$FORGEJO_REF"
