#!/bin/sh -e

ROOTDIR="$PWD"

fj() {
	[ -n "$FJ_TOKEN" ]
}

b2() {
    [ -n "$B2_TOKEN" ] && [ -n "$B2_KEY" ]
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
_end

## build status ##

if [ "$SEND_STATUS" = "1" ]; then
    _group "Sending build status"
    python3 "$ROOTDIR"/.ci/common/status.py --"$STATUS"
    _end
fi

## The actual release ##

if [ "$RELEASE_B2" = "true" ]; then
    if b2; then
        _group "Publishing to B2"

        "$ROOTDIR"/.ci/b2/auth.sh
        "$ROOTDIR"/.ci/b2/release.sh
        _end

        _group "Forgejo Release"

        if fj; then
            # create an external release on Forgejo with the B2 URLs
            "$ROOTDIR"/.ci/fj/release.sh true
        fi
        _end
    fi
elif fj; then
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

