#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Unified CI helper for Forgejo > GitHub integration
# Supports: --parse, --summary, --clone

source ./.ci/common/common.sh

parse_payload() {
  DEFAULT_JSON="default.json"
  PAYLOAD_JSON="payload.json"

  if [ ! -f "$DEFAULT_JSON" ]; then
    echo "You should set 'host', 'repository', 'branch' on $DEFAULT_JSON"
    echo
    echo "Error: $DEFAULT_JSON not found!"
    exit 1
  fi

  FORGEJO_HOST=$(jq -r '.host // empty' $PAYLOAD_JSON)
  if [ -z "$FORGEJO_HOST" ]; then
    FORGEJO_HOST=$(jq -r '.host' $DEFAULT_JSON)
  fi
  FORGEJO_REPO=$(jq -r '.repository // empty' $PAYLOAD_JSON)
  if [ -z "$FORGEJO_REPO" ]; then
    FORGEJO_REPO=$(jq -r '.repository' $DEFAULT_JSON)
  fi

  case "$1" in
    master)
      FORGEJO_REF=$(jq -r '.ref' $PAYLOAD_JSON)
      FORGEJO_BRANCH=master

      FORGEJO_BEFORE=$(jq -r '.before' $PAYLOAD_JSON)
      echo "FORGEJO_BEFORE=$FORGEJO_BEFORE" >> "$GITHUB_ENV"
      ;;
    pull_request)
      FORGEJO_REF=$(jq -r '.ref' $PAYLOAD_JSON)
      FORGEJO_BRANCH=$(jq -r '.branch' $PAYLOAD_JSON)

      FORGEJO_PR_MERGE_BASE=$(jq -r '.merge_base' $PAYLOAD_JSON)
      FORGEJO_PR_NUMBER=$(jq -r '.number' $PAYLOAD_JSON)
      FORGEJO_PR_URL=$(jq -r '.url' $PAYLOAD_JSON)
      FORGEJO_PR_TITLE=$(get_forgejo_field field="title" default_msg="No title provided")

      echo "FORGEJO_PR_MERGE_BASE=$FORGEJO_PR_MERGE_BASE" >> "$GITHUB_ENV"
      echo "FORGEJO_PR_NUMBER=$FORGEJO_PR_NUMBER" >> "$GITHUB_ENV"
      echo "FORGEJO_PR_URL=$FORGEJO_PR_URL" >> "$GITHUB_ENV"
      echo "FORGEJO_PR_TITLE=$FORGEJO_PR_TITLE" >> "$GITHUB_ENV"
      ;;
    tag)
      FORGEJO_REF=$(jq -r '.tag' $PAYLOAD_JSON)
      FORGEJO_BRANCH=stable
      ;;
  esac

  if [ -z "$FORGEJO_REF" ]; then
    FORGEJO_BRANCH=$(jq -r '.branch' $DEFAULT_JSON)
    FORGEJO_REF=$(get_forgejo_field field="sha")
  fi
  FORGEJO_CLONE_URL="https://$FORGEJO_HOST/$FORGEJO_REPO.git"

  echo "FORGEJO_HOST=$FORGEJO_HOST" >> "$GITHUB_ENV"
  echo "FORGEJO_REPO=$FORGEJO_REPO" >> "$GITHUB_ENV"
  echo "FORGEJO_REF=$FORGEJO_REF" >> "$GITHUB_ENV"
  echo "FORGEJO_BRANCH=$FORGEJO_BRANCH" >> "$GITHUB_ENV"
  echo "FORGEJO_CLONE_URL=$FORGEJO_CLONE_URL" >> "$GITHUB_ENV"
}

generate_summary() {
  cat << EOF >> "$GITHUB_STEP_SUMMARY"
## Job Summary
- Triggered By: $1
- Ref: [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF)
EOF

  if [ "$1" = "pull_request" ]; then
    {
      echo "- PR #[${FORGEJO_PR_NUMBER}]($FORGEJO_PR_URL)"
      echo "- Merge Base: [\`$FORGEJO_PR_MERGE_BASE\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_PR_MERGE_BASE)"
      echo -n "- Title: "
      echo "$FORGEJO_PR_TITLE"
      echo
      get_forgejo_field field="body" default_msg="No changelog provided" pull_request_number="$FORGEJO_PR_NUMBER"
    } >> "$GITHUB_STEP_SUMMARY"
  fi
}

clone_repository() {
  TRIES=0

  while ! git clone "$FORGEJO_CLONE_URL" eden; do
    echo "Clone failed!"
    TRIES=$((TRIES + 1))
    if [ "$TRIES" = 10 ]; then
      echo "Failed to clone after ten tries. Exiting."
      exit 1
    fi

    sleep 5
    echo "Trying clone again..."
    rm -rf ./eden || true
  done

  if ! git -C eden checkout "$FORGEJO_REF"; then
    echo "Ref $FORGEJO_REF not found locally, trying to fetch..."
    git -C eden fetch origin "$FORGEJO_REF"
    git -C eden checkout "$FORGEJO_REF"
  fi

  echo "$FORGEJO_BRANCH" > eden/GIT-REFSPEC
  git -C eden rev-parse --short=10 HEAD > eden/GIT-COMMIT
  git -C eden describe --tags HEAD --abbrev=0 > eden/GIT-TAG || echo 'v0.0.3' > eden/GIT-TAG

  if [ "$1" = "tag" ]; then
    cp eden/GIT-TAG eden/GIT-RELEASE
  fi
}

case "$1" in
  --parse)
    parse_payload "$2"
    ;;
  --summary)
    generate_summary "$2"
    ;;
  --clone)
    clone_repository "$2"
    ;;
  *)
    echo "Usage: $0 [--parse <type> | --summary <type> | --clone <type>]"
    echo "Supported types: master | pull_request | tag | push"
    ;;
esac

