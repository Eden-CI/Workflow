#!/bin/sh -e

USAGE="tools/create.sh <BUCKET NAME> <private|public-read|public-read-write>"

bucket="${1:?$USAGE}"
acl="${2:?$USAGE}"

./b2.sh s3api create-bucket --bucket "$bucket" --acl "$acl"
