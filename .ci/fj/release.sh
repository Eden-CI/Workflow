#!/bin/sh -e

# shellcheck disable=SC1091

ROOTDIR="$PWD"
. "$ROOTDIR"/.ci/common/project.sh

DEFAULT_JSON=".ci/default.json"
FJ_HOST=$(jq -r ".[0].host" $DEFAULT_JSON)
FJ_REPO=$(jq -r ".[0].repository" $DEFAULT_JSON)

sed -i "s|$RELEASE_HOST/$RELEASE_REPO|$FJ_HOST/$FJ_REPO|g" changelog.md
git clone --depth 1 https://git.crueter.xyz/scripts/fj.git

echo "-- Creating Release"
fj/fj.sh -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$FORGEJO_REF" \
	create -b changelog.md -n "$PROJECT_PRETTYNAME $FORGEJO_REF" -d

echo "-- Uploading Assets"

# Cloudflare sucks, so we upload twice just to ensure we don't get blocked.
fj/fj.sh -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$FORGEJO_REF" \
	upload -g artifacts/*

fj/fj.sh -k "$FJ_TOKEN" -r "$FJ_REPO" -u "$FJ_HOST" release -t "$FORGEJO_REF" \
	upload -g artifacts/*

export FJ_URL="https://$FJ_HOST/$FJ_REPO/releases/$FORGEJO_REF"