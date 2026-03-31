#!/bin/sh -e

ROOTDIR="$PWD"

if [ "$RELEASE_B2" = "true" ]; then
    "$ROOTDIR"/.ci/b2/auth.sh
    "$ROOTDIR"/.ci/b2/release.sh

    # create an external release on Forgejo with the B2 URLs
    "$ROOTDIR"/.ci/fj/external.sh
else
    # the darkest days are upon us...
    "$ROOTDIR"/.ci/fj/release.sh
fi