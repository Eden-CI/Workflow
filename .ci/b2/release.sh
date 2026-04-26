#!/bin/sh -e

# shellcheck disable=SC1091

ROOTDIR="$PWD"
. "$ROOTDIR/.ci/common/project.sh"
ARTIFACTS_DIR="$ROOTDIR/artifacts"

# upload to a subdir of the main bucket dir
_remote="$B2_DIR$GITHUB_TAG"
_local="$ARTIFACTS_DIR"
_bucket="$B2_BUCKET"

cd "$ROOTDIR/.ci/b2"

_header() {
    echo
    echo "----- $* -----"
    echo
}

## URLS ##
_header "Creating urls.txt"
# get the URLs and put them in a file
# TODO(crueter): Move these off of Forgejo and onto some static page.
find "$_local" -type f | while read -r artifact; do
	_name="$(basename "$artifact")"
	echo "https://$B2_PUBLIC_URL/${GITHUB_TAG}/${_name}"
done > "$ROOTDIR"/urls.txt

echo
cat "$ROOTDIR"/urls.txt
cp "$ROOTDIR"/urls.txt "$_local"

# passed to release.json
_assets=$(jq -R -s -c 'split("\n") | map(select(length > 0))' "$ROOTDIR/urls.txt")

## RELEASE.JSON ##
_header "Creating release.json"
# Fake API endpoint
# TODO(crueter): Automate tagged rels
case "$BUILD_ID" in
    nightly)
        _body="$(cat "$ROOTDIR/nightly-changelog.md")"
        ;;
    tag)
        # FIXME(crueter): Pull from somewhere, idk
        _body="Unimplemented"
        ;;
    *)
        _body="Build: $BUILD_ID"
        ;;
esac

jq -c -n \
    --arg title "$GITHUB_TITLE" \
    --arg tag "$GITHUB_TAG" \
    --arg body "$_body" \
    --arg base "https://$B2_PUBLIC_URL" \
    --argjson assets "$_assets" \
    '{
        tag_name: $tag,
        name: $title,
        body: $body,
        base: $base,
        assets: $assets
    }' > "$_local/release.json"

cat "$_local"/release.json

## UPLOAD ##
_header "Uploading versioned artifacts"
tools/dir.sh "$_bucket" "$_remote" "$_local"

## RM OLD LATEST (except release.json) ##
_header "Deleting old latest"
tools/rm.sh "$_bucket" "latest" --exclude "*.json"

## UPLOAD NEW LATEST ##
_header "Uploading latest artifacts"
tools/dir.sh "$_bucket" "latest" "$_local"

cd "$ROOTDIR"

# Now purge Cloudflare's cache for "latest" zsync and release.json so auto-updaters actually work
if [ -n "$CF_TOKEN" ] && [ -n "$CF_ZONE_ID" ]; then
	_header "Purging Cloudflare cache"

	find "$_local" -name '*.zsync' -o -name '*.json' -o -name '*.txt' | while read -r artifact; do
		_name=$(basename "$artifact")
		echo "https://$B2_PUBLIC_URL/latest/${_name}"
	done > purge.txt

	echo "Purging URLs:"
	cat purge.txt
	echo

	if [ -s purge.txt ]; then
		# shellcheck disable=SC2046
		.ci/cf/purge-cache.sh $(cat purge.txt)
	fi
fi