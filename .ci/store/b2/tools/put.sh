#!/bin/sh -e

USAGE="tools/put.sh <BUCKET> <FILENAME> <LOCAL FILE>"

# TODO(crueter): Make this whole thing more of a CLI
# e.g. here, allow to specify just the dir, and use local filename

bucket="${1:?$USAGE}"
filename="${2:?$USAGE}"
file="${3:?$USAGE}"

[ -f "$file" ] || { echo "File $file does not exist"; exit 1; }

./b2.sh s3api put-object --bucket "$bucket" --key "$filename" --body "$file"
