#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC2090
# shellcheck disable=SC2086
# shellcheck disable=SC2089

get_forgejo_field() {
	field="sha"
	pull_request_number=""
	default_msg="No data provided"

	for arg in "$@"; do
		case $arg in
			field=*)		field="${arg#*=}" ;;
			pull_request_number=*)	pull_request_number="${arg#*=}" ;;
			default_msg=*)		default_msg="${arg#*=}" ;;
			*) exit 1 ;;
		esac
	done

	if [ -n "$FORGEJO_TOKEN" ]; then
		response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $FORGEJO_TOKEN" "https://$FORGEJO_HOST/api/v1/user")

		if [ "$response" -eq 200 ]; then
			auth_header="-H \"Authorization: token $FORGEJO_TOKEN\""
		fi
	fi

	if [ -n "$pull_request_number" ]; then
		url="https://$FORGEJO_HOST/api/v1/repos/$FORGEJO_REPO/pulls/$pull_request_number"
	else
		url="https://$FORGEJO_HOST/api/v1/repos/$FORGEJO_REPO/commits?sha=$FORGEJO_BRANCH&limit=1"
	fi

	data=$(curl -s $auth_header "$url" || true)
	if ! echo "$data" | jq empty; then
		exit 1
	fi

	if [ -n "$pull_request_number" ]; then
		case "$field" in
			title)	result=$(echo "$data" | jq -r '.title // empty') ;;
			body)	result=$(echo "$data" | jq -r '.body // empty') ;;
			sha)	result=$(echo "$data" | jq -r '.head.sha[:10] // empty') ;;
			*)	result="" ;;
		esac
	else
		case "$field" in
			title)	result=$(echo "$data" | jq -r '.[0].commit.message | split("\n")[0] // empty') ;;
			body)	result=$(echo "$data" | jq -r '.[0].commit.message | split("\n")[1:] | join("\n") // empty') ;;
			sha)	result=$(echo "$data" | jq -r '.[0].sha[:10] // empty') ;;
			*)	result="" ;;
		esac
	fi

	echo "${result:-$default_msg}"
}
