#!/bin/sh -e

# TODO: make this extensible to PRs, etc.

_body="# $GITHUB_TITLE

New build published at https://$RELEASE_HOST/$RELEASE_REPO/releases/tag/$GITHUB_TAG"
_avatar="https://git.eden-emu.dev/eden-emu/eden/raw/branch/master/dist/qt_themes/default/icons/256x256/eden.png"

PAYLOAD=$(jq -c -n \
	--arg content "$_body" \
	--arg avatar "$_avatar" \
'
{
	content: $content,
	username: "Eden - Nightly Builds",
	avatar_url: $avatar
}
')

curl -H "Content-Type: application/json" -d "$PAYLOAD" "$DISCORD_WEBHOOK"
