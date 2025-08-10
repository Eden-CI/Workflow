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
    FORGEJO_BODY=$(FIELD=body DEFAULT_MSG="No changelog provided" FORGEJO_NUMBER=$FORGEJO_NUMBER python3 .ci/changelog/pr_field.py)
    
    ESCAPED_TITLE=$(printf '%q' "$FORGEJO_TITLE")
    ESCAPED_BODY=$(printf '%q' "$FORGEJO_BODY")

    echo "FORGEJO_TITLE=$ESCAPED_TITLE" >> $GITHUB_ENV
    echo "FORGEJO_BODY=$ESCAPED_BODY" >> $GITHUB_ENV
    ;;
  tag)
    FORGEJO_REF=$(echo "$PAYLOAD_JSON" | jq -r '.tag')

    echo "FORGEJO_CLONE_URL=https://git.eden-emu.dev/eden-emu/eden.git" >> $GITHUB_ENV
    ;;
  push)
    echo "FORGEJO_CLONE_URL=https://git.eden-emu.dev/eden-emu/eden.git" >> $GITHUB_ENV
    FORGEJO_REF=origin/macos
esac

if [ "$FORGEJO_REF" = "null" ] || [ "$FORGEJO_REF" = "" ]
then
  FORGEJO_REF="origin/macos"
fi

echo "FORGEJO_REF=$FORGEJO_REF" >> $GITHUB_ENV