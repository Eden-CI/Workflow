#!/bin/sh -e

# shellcheck disable=SC1091

ROOTDIR="$PWD"
. "$ROOTDIR/.ci/common/project.sh"
# ARTIFACTS_DIR="$ROOTDIR/artifacts"
ARTIFACTS_DIR="${1:?}"

# upload to a subdir of the main bucket dir
_dir="$B2_DIR$GITHUB_TAG"
_local="$ARTIFACTS_DIR"
_bucket="$B2_BUCKET"

cd "$ROOTDIR/.ci/b2"

# Fake API endpoint
# TODO(crueter): Automate tagged rels
case "$BUILD_ID" in
	nightly)
		_log="$ROOTDIR/changelogs"
		mkdir -p "$_log"
		jq -c -n \
			--arg title "$GITHUB_TITLE" \
			--arg tag "$GITHUB_TAG" \
			--arg body "$(cat "$ROOTDIR"/nightly-changelog.md)" \
			--arg base "https://$B2_PUBLIC_URL" \
			'{tag_name: $tag, name: $title, body: $body, base: $base}' > "$_local"/release.json
		;;
	# FIXME(crueter): Pull from somewhere, idk
	tag)
		_log="$ROOTDIR/changelogs"
		mkdir -p "$_log"
		jq -c -n \
			--arg title "$GITHUB_TITLE" \
			--arg tag "$GITHUB_TAG" \
			--arg body "Unimplemented" \
			--arg base "https://$B2_PUBLIC_URL" \
			'{tag_name: $tag, name: $title, body: $body, base: $base}' > "$_local"/release.json
		;;
esac

# Upload
# tools/dir.sh "$_bucket" "$_dir" "$_local"

# and get the URLs and put them in a file
# TODO(crueter): Move these off of Forgejo and onto some static page.
tools/url.sh "$_bucket" "$_dir" >"$ROOTDIR/urls.txt"

# Latest rels
# These are still versioned
# FIXME(crueter): Zsync may be temporarily unavailable? Not a big deal tbh
tools/rm.sh "$_bucket" "latest" --exclude "*.json"
tools/dir.sh "$_bucket" "latest" "$_local"

cd "$ROOTDIR"