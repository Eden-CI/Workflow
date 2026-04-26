#!/bin/sh -e

# Purges a Cloudflare cache (mainly useful for purging latest stuff)

: "${CF_ZONE_ID:?You must set ZONE_ID to your Cloudflare domain zone ID}"
: "${CF_TOKEN:?You must set API_TOKEN to your Cloudflare API token}"

data=$(jq -n --args '{files: $ARGS.positional}' "$@")

curl --fail -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/purge_cache" \
     -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" --data "$data"

echo
