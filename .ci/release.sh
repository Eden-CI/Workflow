#!/bin/sh -e

# early exit :)
[ -n "$RELEASE_HOST" ] || exit 0

ROOTDIR="$PWD"

fj() {
	[ -n "$FJ_TOKEN" ]
}

b2() {
    [ -n "$B2_TOKEN" ] && [ -n "$B2_KEY" ]
}

release() {
    [ "$RELEASE_FJ" = "1" ]
}

_group() {
    echo "##[group]$*"
}

_end() {
    echo "##[endgroup]"
}

## Pack ##

_group "Packaging artifacts nicely"
"$ROOTDIR"/.ci/common/pack.sh
_end

## Changelog ##
_group "Generating changelog"
"$ROOTDIR"/.ci/changelog/generate.sh "$BUILD_ID" > changelog.md
cat changelog.md
_end

## build status ##

if [ "$SEND_STATUS" = "1" ]; then
    _group "Sending build status"
    python3 "$ROOTDIR"/.ci/common/status.py --"$STATUS"
    _end
fi

## The actual release ##

if release && b2 && [ "$RELEASE_B2" = "true" ]; then
    _group "Publishing to B2"
    "$ROOTDIR"/.ci/b2/auth.sh
    "$ROOTDIR"/.ci/b2/release.sh
    _end

    # create an external release on Forgejo with the B2 URLs
    if fj; then
        _group "Forgejo Release"
        "$ROOTDIR"/.ci/fj/release.sh true
        _end
    fi
elif release && fj; then
    # the darkest days are upon us...
    _group "Forgejo Release"
    "$ROOTDIR"/.ci/fj/release.sh false
    _end
fi

## Miscellaneous dist handling ##

## Discord ##

if [ "$RELEASE_DISCORD" = "1" ]; then
    _group "Publishing to Discord"
    "$ROOTDIR"/.ci/discord/publish.sh
    _end
fi

## Torrent ##

if [ "$RELEASE_TAG" = "1" ] && [ -n "$VPS_SSH_PRIV" ]; then
    _group "Publishing to Discord"
    "$ROOTDIR"/.ci/fj/torrent.sh
    _end
fi

