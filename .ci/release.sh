#!/bin/sh -e

ROOTDIR="$PWD"

fj() {
	[ -n "$FJ_TOKEN" ]
}

b2() {
    [ -n "$B2_TOKEN" ] && [ -n "$B2_KEY" ]
}

if [ "$RELEASE_B2" = "true" ]; then
    if b2; then
        "$ROOTDIR"/.ci/b2/auth.sh
        "$ROOTDIR"/.ci/b2/release.sh

        if fj; then
            # create an external release on Forgejo with the B2 URLs
            "$ROOTDIR"/.ci/fj/external.sh
        fi
    fi
elif fj; then
    # the darkest days are upon us...
    "$ROOTDIR"/.ci/fj/release.sh
fi