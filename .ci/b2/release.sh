#!/bin/sh -e

# shellcheck disable=SC1091

ROOTDIR="$PWD"
. "$ROOTDIR/.ci/common/project.sh"
ARTIFACTS_DIR="$ROOTDIR/artifacts"

# upload to a subdir of the main bucket dir
_dir="$B2_DIR/$GITHUB_TAG"
_local="$ARTIFACTS_DIR"
_bucket="$B2_BUCKET"

# now upload. :)
cd "$ROOTDIR/.ci/b2"

tools/dir.sh "$_bucket" "$_dir" "$_local"

# and get the URLs and put them in a file
tools/url.sh "$_bucket" "$_dir" >"$ROOTDIR/urls.txt"

cd "$ROOTDIR"