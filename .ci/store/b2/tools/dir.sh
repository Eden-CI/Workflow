#!/bin/sh -e

# Upload a directory

USAGE="tools/dir.sh <BUCKET> <REMOTE DIR> <LOCAL DIR>"

# TODO(crueter): Make this whole thing more of a CLI

bucket="${1:?$USAGE}"
remote="${2:?$USAGE}"
dir="${3:?$USAGE}"

shift 3

[ -d "$dir" ] || { echo "Local directory $dir does not exist"; exit 1; }

./b2.sh s3 cp "$dir" "s3://$bucket/$remote" --recursive "$@"
