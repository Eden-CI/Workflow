#!/bin/sh -ex

TAG=v${TIMESTAMP}.${FORGEJO_REF}
REF=${FORGEJO_REF}

brief() {
echo "This is ref [\`$REF\`](https://git.eden-emu.dev/eden-emu/eden/commit/$REF) of Eden's master branch."
}

changelog() {
  echo "## Changelog"
  echo
  echo "Full changelog: [\`$FORGEJO_BEFORE...$FORGEJO_REF\`](https://git.eden-emu.dev/eden-emu/eden/compare/$FORGEJO_BEFORE...$FORGEJO_REF)"
  echo
}