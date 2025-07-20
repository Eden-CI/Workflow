PAYLOAD_JSON='${{ toJSON(github.event.client_payload) }}'
declare FORGEJO_REF=""

case "$1" in
  master)
    FORGEJO_REF=$(echo "$PAYLOAD_JSON" | jq -r '.ref')

    echo "FORGEJO_CLONE_URL=https://git.eden-emu.dev/eden-emu/eden.git" >> $GITHUB_ENV
    ;;
  pull_request)
    FORGEJO_REF=$(echo "$PAYLOAD_JSON" | jq -r '.ref')

    echo "FORGEJO_CLONE_URL=$(echo "$PAYLOAD_JSON" | jq -r '.clone_url')" >> $GITHUB_ENV
    echo "FORGEJO_NUMBER=$(echo "$PAYLOAD_JSON" | jq -r '.number')" >> $GITHUB_ENV
    echo "FORGEJO_REPOSITORY=$(echo "$PAYLOAD_JSON" | jq -r '.repository')" >> $GITHUB_ENV
    echo "FORGEJO_TITLE=$(echo "$PAYLOAD_JSON" | jq -r '.title')" >> $GITHUB_ENV
    echo "FORGEJO_PR_URL=$(echo "$PAYLOAD_JSON" | jq -r '.url')" >> $GITHUB_ENV
    ;;
  tag)
    FORGEJO_REF=$(echo "$PAYLOAD_JSON" | jq -r '.tag')

    echo "FORGEJO_CLONE_URL=https://git.eden-emu.dev/eden-emu/eden.git" >> $GITHUB_ENV
    ;;
esac

if [ "$FORGEJO_REF" == "null" ]
then
  FORGEJO_REF="master"
fi

echo "FORGEJO_REF=$FORGEJO_REF" >> $GITHUB_ENV