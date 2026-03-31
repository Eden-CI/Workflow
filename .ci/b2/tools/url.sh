#!/bin/sh -e

# Get url from object(s)

USAGE="tools/url.sh <BUCKET> <QUERY>"

bucket="${1:?$USAGE}"
dir="${2:?$USAGE}"

./b2.sh s3api list-objects --bucket "$bucket" --prefix "$dir" --query 'Contents[].[Key]' --output text | xargs -I {} echo "https://$bucket.$B2_URL/{}"
