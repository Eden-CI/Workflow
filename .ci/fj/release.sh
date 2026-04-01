#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091
# shellcheck disable=SC2046

# TODO(crueter): DEDUP

ROOTDIR="$PWD"
. "$ROOTDIR/.ci/common/project.sh"

_external="$1"
external() {
    [ "$_external" = "true" ]
}

_header() {
    echo
    echo "----- $* -----"
    echo
}

FJ_HOST="$RELEASE_HOST"
FJ_REPO="$RELEASE_REPO"

## Make changelog ##
if external; then
    _find="$RELEASE_HOST/$RELEASE_REPO/releases/download"
    _replace="$B2_BUCKET.$B2_URL/$B2_DIR"
else
    _find="$RELEASE_HOST/$RELEASE_REPO"
    _replace="$FJ_HOST/$FJ_REPO"
fi

sed -i "s|$_find|$_replace|g" "$ROOTDIR/changelog.md"

## fjcli ##
git clone --depth 1 https://git.crueter.xyz/scripts/fj.git

## make release ##
_header "Creating Release"

"$ROOTDIR/fj/fj.sh" -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$GITHUB_TAG" \
	create -b "$ROOTDIR/changelog.md" -n "$GITHUB_TITLE" -a -r

## Uploading ##

_header "Uploading Assets"

if external; then
    "$ROOTDIR/fj/fj.sh" -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$GITHUB_TAG" \
        external $(cat "$ROOTDIR"/urls.txt)
else
    # Cloudflare sucks, so we upload twice just to ensure we don't get blocked.
    "$ROOTDIR/fj/fj.sh" -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$GITHUB_TAG" \
        upload -g "$ARTIFACTS_DIR"/*

    "$ROOTDIR/fj/fj.sh" -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$GITHUB_TAG" \
        upload -g "$ARTIFACTS_DIR"/*
fi

## Summary ##

FJ_URL="https://$FJ_HOST/$FJ_REPO/releases/tag/$GITHUB_TAG"

if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    {
        echo "## Release Summary"
        echo "- View Release on Forgejo: [$GITHUB_TITLE]($FJ_URL)"
    } >> "$GITHUB_STEP_SUMMARY"
fi

## Release Status ##

if [ "$SEND_STATUS" = "1" ]; then
    _header "Sending Release status"
    "$ROOTDIR/.ci/status/status.sh" --release "$FJ_URL"
fi

## PR Number ##

if [ "$RELEASE_PR" = 1 ]; then
    _header "PR RELEASE"

    "$ROOTDIR/fj/fj.sh" -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$FORGEJO_PR_NUMBER" \
        create -b "$ROOTDIR/changelog.md" -n "$GITHUB_TITLE" -a -r
fi