#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Unified CI helper for Forgejo > GitHub integration
# Supports: --parse, --summary, --clone

DEBUG=${DEBUG:-1}

log_debug() {
    if [ "$DEBUG" = "1" ]; then
        echo "[DEBUG] $@" >&2
    fi
}

forgejo_api_get() {
  local url="$1"
  local response
  local retries=5
  local delay=10

  for i in $(seq 1 $retries); do
    echo "[DEBUG] Fetching (attempt $i/$retries): $url"
    response=$(curl -sSL -H "Authorization: token ${FORGEJO_TOKEN}" "$url")

    # Testa se é JSON válido
    if echo "$response" | jq empty 2>/dev/null; then
      echo "$response"
      return 0
    fi

    echo "[WARN] Non-JSON response (maybe Cloudflare). Retrying in $delay seconds..."
    echo "[DEBUG] Raw response snippet: $(echo "$response" | head -n 5)"
    sleep "$delay"
  done

  echo "[ERROR] All retries failed: Cloudflare still blocking."
  return 1
}

get_forgejo_field() {
    local field="sha"
    local pull_request_number=""
    local default_msg="No data provided"

    for arg in "$@"; do
        case $arg in
            field=*)        field="${arg#*=}" ;;
            pull_request_number=*) pull_request_number="${arg#*=}" ;;
            default_msg=*)  default_msg="${arg#*=}" ;;
            *) echo "Unknown argument: $arg" >&2 ;;
        esac
    done

    local url
    local data
    local result

    local auth_header=()
    if [ -n "$FORGEJO_TOKEN" ]; then
        auth_header+=(-H "Authorization: token $FORGEJO_TOKEN")
        log_debug "Using Forgejo token for authentication"
    else
        log_debug "No Forgejo token provided"
    fi

    auth_header+=(
        -A "Mozilla/5.0 (X11; Linux x86_64; rv:132.0) Gecko/20100101 Firefox/132.0"
        -H "Accept: application/json"
    )

    if [[ -n "$pull_request_number" ]]; then
        url="https://$FORGEJO_HOST/api/v1/repos/$FORGEJO_REPO/pulls/$pull_request_number"
    else
        url="https://$FORGEJO_HOST/api/v1/repos/$FORGEJO_REPO/commits?sha=$FORGEJO_BRANCH&limit=1"
    fi

    forgejo_api_get

    log_debug "Fetching URL: $url"
    data=$(curl -sS "${auth_header[@]}" "$url" || true)

    log_debug "Raw response from Forgejo:"
    echo "$data" | jq . >&2 || echo "[DEBUG] Non-JSON response: $data" >&2

    if [[ -n "$pull_request_number" ]]; then
        case "$field" in
            title) result=$(echo "$data" | jq -r '.title // empty') ;;
            body)  result=$(echo "$data" | jq -r '.body // empty') ;;
            sha)   result=$(echo "$data" | jq -r '.head.sha[:10] // empty') ;;
            *)     result="" ;;
        esac
    else
        case "$field" in
            title) result=$(echo "$data" | jq -r '.[0].commit.message | split("\n")[0] // empty') ;;
            body)  result=$(echo "$data" | jq -r '.[0].commit.message | split("\n")[1:] | join("\n") // empty') ;;
            sha)   result=$(echo "$data" | jq -r '.[0].sha[:10] // empty') ;;
            *)     result="" ;;
        esac
    fi

    if [ -z "$result" ]; then
        log_debug "No data found for field '$field', using default message."
    else
        log_debug "Extracted field '$field': $result"
    fi

    echo "${result:-$default_msg}"
}

parse_payload() {
  DEFAULT_JSON="default.json"
  PAYLOAD_JSON="payload.json"

  if [ ! -f "$DEFAULT_JSON" ]; then
    echo "You should set 'host', 'repository', 'branch' on $DEFAULT_JSON"
    echo
    echo "Error: $DEFAULT_JSON not found!"
    exit 1
  fi

  log_debug "Reading configuration from JSON files"

  FORGEJO_HOST=$(jq -r '.host // empty' $PAYLOAD_JSON)
  if [ -z "$FORGEJO_HOST" ]; then
    FORGEJO_HOST=$(jq -r '.host' $DEFAULT_JSON)
  fi
  FORGEJO_REPO=$(jq -r '.repository // empty' $PAYLOAD_JSON)
  if [ -z "$FORGEJO_REPO" ]; then
    FORGEJO_REPO=$(jq -r '.repository' $DEFAULT_JSON)
  fi

  log_debug "FORGEJO_HOST=$FORGEJO_HOST"
  log_debug "FORGEJO_REPO=$FORGEJO_REPO"

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
      FORGEJO_PR_TITLE=$(get_forgejo_field field="title" default_msg="No title provided" pull_request_number="$FORGEJO_PR_NUMBER")
      log_debug "Pull Request #$FORGEJO_PR_NUMBER for branch $FORGEJO_BRANCH"

      echo "FORGEJO_PR_MERGE_BASE=$FORGEJO_PR_MERGE_BASE" >> "$GITHUB_ENV"
      echo "FORGEJO_PR_NUMBER=$FORGEJO_PR_NUMBER" >> "$GITHUB_ENV"
      echo "FORGEJO_PR_URL=$FORGEJO_PR_URL" >> "$GITHUB_ENV"
      echo "FORGEJO_PR_TITLE=$FORGEJO_PR_TITLE" >> "$GITHUB_ENV"
      ;;
    tag)
      FORGEJO_REF=$(jq -r '.tag' $PAYLOAD_JSON)
      FORGEJO_BRANCH=stable
      ;;
    push|test)
      FORGEJO_BRANCH=$(jq -r '.branch' $DEFAULT_JSON)
      log_debug "Detected branch=$FORGEJO_BRANCH"
      FORGEJO_REF=$(get_forgejo_field field="sha")
      ;;
    *)
      echo "Type: $1"
      echo "Supported types: master | pull_request | tag | push | test"
      exit 1
  esac

  FORGEJO_CLONE_URL="https://$FORGEJO_HOST/$FORGEJO_REPO.git"

  log_debug "FORGEJO_REF=$FORGEJO_REF"
  log_debug "FORGEJO_BRANCH=$FORGEJO_BRANCH"
  log_debug "FORGEJO_CLONE_URL=$FORGEJO_CLONE_URL"

  echo "FORGEJO_HOST=$FORGEJO_HOST" >> "$GITHUB_ENV"
  echo "FORGEJO_REPO=$FORGEJO_REPO" >> "$GITHUB_ENV"
  echo "FORGEJO_REF=$FORGEJO_REF" >> "$GITHUB_ENV"
  echo "FORGEJO_BRANCH=$FORGEJO_BRANCH" >> "$GITHUB_ENV"
  echo "FORGEJO_CLONE_URL=$FORGEJO_CLONE_URL" >> "$GITHUB_ENV"
}

generate_summary() {
  echo "## Job Summary" >> "$GITHUB_STEP_SUMMARY"
  echo "- Triggered By: $1" >> "$GITHUB_STEP_SUMMARY"
  echo "- Commit: [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF)" >> "$GITHUB_STEP_SUMMARY"
  echo >> "$GITHUB_STEP_SUMMARY"

  case "$1" in
    master)
      echo "## Master Build" >> "$GITHUB_STEP_SUMMARY"
      echo "- Full changelog: [\`$FORGEJO_BEFORE...$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/compare/$FORGEJO_BEFORE...$FORGEJO_REF)" >> "$GITHUB_STEP_SUMMARY"
      ;;
    pull_request)
      echo "## Pull Request Build" >> "$GITHUB_STEP_SUMMARY"
      echo "- Pull Request: #[${FORGEJO_PR_NUMBER}]($FORGEJO_PR_URL)" >> "$GITHUB_STEP_SUMMARY"
      echo "- Merge Base Commit: [\`$FORGEJO_PR_MERGE_BASE\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_PR_MERGE_BASE)" >> "$GITHUB_STEP_SUMMARY"
      echo "- PR Title: $FORGEJO_PR_TITLE" >> "$GITHUB_STEP_SUMMARY"
      echo >> "$GITHUB_STEP_SUMMARY"
      echo "### Changelog" >> "$GITHUB_STEP_SUMMARY"
      get_forgejo_field field="body" default_msg="No changelog provided" pull_request_number="$FORGEJO_PR_NUMBER" >> "$GITHUB_STEP_SUMMARY"
      ;;
    push|test)
      echo "## Continuous Integration Test Build" >> "$GITHUB_STEP_SUMMARY"
      echo "- This build was triggered for testing purposes." >> "$GITHUB_STEP_SUMMARY"
      ;;
    *)
      echo "## Unknown Build Type" >> "$GITHUB_STEP_SUMMARY"
      echo "- Build type '$1' is not recognized." >> "$GITHUB_STEP_SUMMARY"
      ;;
  esac

  echo >> "$GITHUB_STEP_SUMMARY"
}

clone_repository() {
  TRIES=0
  log_debug "Cloning repository: $FORGEJO_CLONE_URL"

  while ! git clone "$FORGEJO_CLONE_URL" eden; do
    echo "Clone failed!"
    TRIES=$((TRIES + 1))
    if [ "$TRIES" = 10 ]; then
      echo "Failed to clone after $TRIES tries. Exiting."
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
    echo "Supported types: master | pull_request | tag | push | test"
    ;;
esac
