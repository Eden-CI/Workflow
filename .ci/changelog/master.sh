#!/bin/sh -ex

TAG=v${TIMESTAMP}.${FORGEJO_REF}
REF=${FORGEJO_REF}

brief() {
echo "This is ref [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF) of Eden's master branch."
}

changelog() {
  echo "## Changelog"
  echo
  echo "Full changelog: [\`$FORGEJO_BEFORE...$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/compare/$FORGEJO_BEFORE...$FORGEJO_REF)"
  echo
}
