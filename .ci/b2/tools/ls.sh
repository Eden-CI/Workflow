#!/bin/sh -e

# TODO(crueter): URLs?
USAGE="tools/ls.sh <BUCKET> <QUERY>"

bucket="${1:?$USAGE}"
dir="${2:?$USAGE}"

./b2.sh s3api list-objects --bucket "$bucket" --prefix "$dir" --query 'Contents[].[Key]' --output text
