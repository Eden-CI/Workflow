#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

get_forgejo_field() {
    local field="sha"
    local pull_request=""
    local default_msg="No data provided"

    for arg in "$@"; do
        case $arg in
            field=*)        field="${arg#*=}" ;;
            pull_request=*) pull_request="${arg#*=}" ;;
            default_msg=*)  default_msg="${arg#*=}" ;;
            *) echo "Unknown argument: $arg" >&2 ;;
        esac
    done

    local url
    local data
    local result

    local auth_header=()
    if [ -n "$FORGEJO_TOKEN" ]; then
        auth_header=(-H "Authorization: token $FORGEJO_TOKEN")
    fi

    if [[ -n "$pull_request" ]]; then
        url="https://$FORGEJO_HOST/api/v1/repos/$FORGEJO_REPO/pulls/$pull_request"
        data=$(curl -s "${auth_header[@]}" "$url" || true)

        case "$field" in
            title) result=$(echo "$data" | jq -r '.title // empty') ;;
            body)  result=$(echo "$data" | jq -r '.body // empty') ;;
            sha)   result=$(echo "$data" | jq -r '.head.sha[:10] // empty') ;;
            *)     result="" ;;
        esac
    else
        url="https://$FORGEJO_HOST/api/v1/repos/$FORGEJO_REPO/commits?sha=$FORGEJO_BRANCH&limit=1"
        data=$(curl -s "${auth_header[@]}" "$url" || true)

        case "$field" in
            title) result=$(echo "$data" | jq -r '.[0].commit.message | split("\n")[0] // empty') ;;
            body)  result=$(echo "$data" | jq -r '.[0].commit.message | split("\n")[1:] | join("\n") // empty') ;;
            sha)   result=$(echo "$data" | jq -r '.[0].sha[:10] // empty') ;;
            *)     result="" ;;
        esac
    fi

    echo "${result:-$default_msg}"
}
