#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Unified CI helper for Forgejo > GitHub integration
# Supports: --parse, --summary, --clone

parse_payload() {
  echo "$PAYLOAD_JSON"

  DEFAULT=update-fmt

  case "$1" in
    master)
      FORGEJO_REF=$(echo "$PAYLOAD_JSON" | jq -r '.ref')
      FORGEJO_BEFORE=$(echo "$PAYLOAD_JSON" | jq -r '.before')
      FORGEJO_BRANCH=master

      echo "FORGEJO_CLONE_URL=https://git.eden-emu.dev/eden-emu/eden.git" >> "$GITHUB_ENV"
      echo "FORGEJO_BEFORE=$FORGEJO_BEFORE" >> "$GITHUB_ENV"
      ;;
    pull_request)
      FORGEJO_REF=$(echo "$PAYLOAD_JSON" | jq -r '.ref')
      FORGEJO_BRANCH=$(echo "$PAYLOAD_JSON" | jq -r '.branch')
      FORGEJO_NUMBER=$(echo "$PAYLOAD_JSON" | jq -r '.number')

      echo "FORGEJO_CLONE_URL=$(echo "$PAYLOAD_JSON" | jq -r '.clone_url')" >> "$GITHUB_ENV"
      echo "FORGEJO_NUMBER=$FORGEJO_NUMBER" >> "$GITHUB_ENV"
      echo "FORGEJO_PR_URL=$(echo "$PAYLOAD_JSON" | jq -r '.url')" >> "$GITHUB_ENV"
      echo "FORGEJO_MERGE_BASE=$(echo "$PAYLOAD_JSON" | jq -r '.merge_base')" >> "$GITHUB_ENV"

      # thanks POSIX
      FORGEJO_TITLE=$(FIELD=title DEFAULT_MSG="No title provided" FORGEJO_NUMBER=$FORGEJO_NUMBER python3 .ci/changelog/pr_field.py)
      echo "FORGEJO_TITLE=$FORGEJO_TITLE" >> "$GITHUB_ENV"
      ;;
    tag)
      FORGEJO_REF=$(echo "$PAYLOAD_JSON" | jq -r '.tag')
      FORGEJO_BRANCH=stable

      echo "FORGEJO_CLONE_URL=https://git.eden-emu.dev/eden-emu/eden.git" >> "$GITHUB_ENV"
      ;;
    push)
      echo "FORGEJO_CLONE_URL=https://git.eden-emu.dev/eden-emu/eden.git" >> "$GITHUB_ENV"
      FORGEJO_REF="origin/$DEFAULT"
      FORGEJO_BRANCH="$DEFAULT"
      ;;
  esac

  if [ "$FORGEJO_REF" = "null" ] || [ -z "$FORGEJO_REF" ]; then
    FORGEJO_REF="origin/$DEFAULT"
    FORGEJO_BRANCH="$DEFAULT"
  fi

  echo "FORGEJO_REF=$FORGEJO_REF" >> "$GITHUB_ENV"
  echo "FORGEJO_BRANCH=$FORGEJO_BRANCH" >> "$GITHUB_ENV"
}

generate_summary() {
  cat << EOF >> "$GITHUB_STEP_SUMMARY"
## Job Summary
-- Triggered By: $1
-- Ref: [\`$FORGEJO_REF\`](https://git.eden-emu.dev/eden-emu/eden/commit/$FORGEJO_REF)
EOF

  if [ "$1" = "pull_request" ]; then
    {
      echo "- PR #[${FORGEJO_NUMBER}]($FORGEJO_PR_URL)"
      echo "- Merge Base: [\`$FORGEJO_MERGE_BASE\`](https://git.eden-emu.dev/eden-emu/eden/commit/$FORGEJO_MERGE_BASE)"
      echo -n "- Title: "
      echo "$FORGEJO_TITLE"
      echo
      FIELD=body DEFAULT_MSG="No changelog provided" FORGEJO_NUMBER=$FORGEJO_NUMBER python3 .ci/changelog/pr_field.py
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

