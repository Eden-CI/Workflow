#!/bin/sh -e

# TODO(crueter): URLs?
USAGE="tools/ls.sh <BUCKET>"

bucket="${1:?$USAGE}"
shift

./b2.sh s3api list-objects --bucket "$bucket" --query 'Contents[].[Key]' --output text "$@"
