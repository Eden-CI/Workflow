#!/bin/bash -x

echo $PAYLOAD_JSON

case "$1" in
  master)
    FORGEJO_REF=$(echo "$PAYLOAD_JSON" | jq -r '.ref')

    echo "FORGEJO_CLONE_URL=https://git.eden-emu.dev/eden-emu/eden.git" >> $GITHUB_ENV
    ;;
  pull_request)
    FORGEJO_REF=$(echo "$PAYLOAD_JSON" | jq -r '.ref')
    FORGEJO_NUMBER=$(echo "$PAYLOAD_JSON" | jq -r '.number')

    echo "FORGEJO_CLONE_URL=$(echo "$PAYLOAD_JSON" | jq -r '.clone_url')" >> $GITHUB_ENV
    echo "FORGEJO_NUMBER=$FORGEJO_NUMBER" >> $GITHUB_ENV
    echo "FORGEJO_PR_URL=$(echo "$PAYLOAD_JSON" | jq -r '.url')" >> $GITHUB_ENV

    # thanks POSIX
    FORGEJO_TITLE=$(FIELD=title DEFAULT_MSG="No title provided" FORGEJO_NUMBER=$FORGEJO_NUMBER python3 .ci/changelog/pr_field.py)
    echo FORGEJO_TITLE="$FORGEJO_TITLE" >> $GITHUB_ENV
    ;;
  tag)
    FORGEJO_REF=$(echo "$PAYLOAD_JSON" | jq -r '.tag')

    echo "FORGEJO_CLONE_URL=https://git.eden-emu.dev/eden-emu/eden.git" >> $GITHUB_ENV
    ;;
  push)
    echo "FORGEJO_CLONE_URL=https://git.eden-emu.dev/eden-emu/eden.git" >> $GITHUB_ENV
    FORGEJO_REF=refactor/cpmfile
esac

if [ "$FORGEJO_REF" = "null" ] || [ "$FORGEJO_REF" = "" ]
then
  FORGEJO_REF="refactor/cpmfile"
fi

echo "FORGEJO_REF=$FORGEJO_REF" >> $GITHUB_ENV