#!/bin/sh -e

# shellcheck disable=SC1091

ROOTDIR="$PWD"
. "$ROOTDIR/.ci/build/project.sh"
ARTIFACTS_DIR="$ROOTDIR/artifacts"

# upload to a subdir of the main bucket dir
_remote="$B2_DIR$GITHUB_TAG"
_local="$ARTIFACTS_DIR"
_bucket="$B2_BUCKET"

cd "$ROOTDIR/.ci/store/b2"

_header() {
    echo
    echo "----- $* -----"
    echo
}

# Fake API endpoint
# TODO(crueter): Automate tagged rels
case "$BUILD_ID" in
    nightly)
        _body="$ROOTDIR/nightly-changelog.md"
        ;;
    tag)
        _body="$ROOTDIR/releasenotes/$GITHUB_TAG.md"
        ;;
    *)
		# This codepath is unimplemented and unused
        _body=/dev/null
        ;;
esac

## URLS ##
_header "Creating assets.json"

# get the URLs and put them in a file
# TODO(crueter): Move these off of Forgejo and onto some static page.
find "$_local" -type f | while read -r artifact; do
	case "$artifact" in
		*.json) continue ;;
	esac

	_name="$(basename "$artifact")"
	_url="https://$B2_PUBLIC_URL/${GITHUB_TAG}/${_name}"
	_size="$(stat -c "%s" "$artifact")"
	_date="$(date -Iseconds)"
	_digest="sha256:$(sha256sum "$artifact" | cut -d' ' -f1)"

	jq -c -n \
		--arg name "$_name" \
		--arg date "$_date" \
		--arg size "$_size" \
		--arg url "$_url" \
		--arg digest "$_digest" \
		'{
			name: $name,
			size: ($size | tonumber),
			digest: $digest,
			created_at: $date,
			browser_download_url: $url
		}'
done | jq -s '.' > "$ROOTDIR"/assets.json

echo
cat "$ROOTDIR"/assets.json | jq -r '.'
cp "$ROOTDIR"/assets.json "$_local"

# passed to release.json
_assets=$(cat "$ROOTDIR"/assets.json)

## RELEASE.JSON ##
_header "Creating release.json"

_date="$(date -Iseconds)"
_url="https://$RELEASE_HOST/$RELEASE_REPO/releases/tag/$GITHUB_TAG"

jq -c -n \
    --arg title "$GITHUB_TITLE" \
    --arg tag "$GITHUB_TAG" \
    --arg body "$(cat "$_body")" \
	--arg date "$_date" \
	--arg url "$_url" \
    --argjson assets "$_assets" \
    '{
        tag_name: $tag,
        name: $title,
		html_url: $url,
        body: $body,
		created_at: $date,
		published_at: $date,
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
		.ci/store/cf/purge-cache.sh $(cat purge.txt)
	fi
fi