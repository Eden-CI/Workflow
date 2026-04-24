#!/bin/sh -e

# Upload a directory

USAGE="tools/rm.sh <BUCKET> <REMOTE DIR>"

# TODO(crueter): Make this whole thing more of a CLI

bucket="${1:?$USAGE}"
remote="${2:?$USAGE}"

shift 2

echo ./b2.sh s3 rm "s3://$bucket/$remote" --recursive "$@"
./b2.sh s3 rm "s3://$bucket/$remote" --recursive "$@"
