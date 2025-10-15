#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Unified CI helper for Forgejo > GitHub integration
# Supports: --parse, --summary, --clone

# shellcheck disable=SC1090

load_payload_env() {
	FORGEJO_LENV="forgejo.env"

	if [ -f "$FORGEJO_LENV" ]; then
		if [ "$CI" = "true" ]; then
			# Safe export to GITHUB_ENV
			while IFS= read -r line; do
				echo "$line" >> "$GITHUB_ENV"
			done <"$FORGEJO_LENV"
		else
			set -a
			. "$FORGEJO_LENV"
			set +a
		fi
	fi
}

parse_payload() {
	DEFAULT_JSON="default.json"
	PAYLOAD_JSON="payload.json"
	FORGEJO_LENV="forgejo.env"

	: >"$FORGEJO_LENV"

	if [ ! -f "$PAYLOAD_JSON" ]; then
		echo "null" >$PAYLOAD_JSON
	fi
	if [ ! -f "$DEFAULT_JSON" ]; then
		echo "You should set 'host', 'repository', 'branch' on $DEFAULT_JSON"
		echo
		echo "Error: $DEFAULT_JSON not found!"
		exit 1
	fi

	FORGEJO_HOST=$(jq -r '.host // empty' $PAYLOAD_JSON)
	FORGEJO_REPO=$(jq -r '.repository // empty' $PAYLOAD_JSON)
	if [ -z "$FORGEJO_HOST" ] || [ -z "$FORGEJO_REPO" ]; then
		FALLBACK_IDX=0
		FORGEJO_HOST=$(jq -r ".[$FALLBACK_IDX].host" $DEFAULT_JSON)
		FORGEJO_REPO=$(jq -r ".[$FALLBACK_IDX].repository" $DEFAULT_JSON)
	fi
	FORGEJO_HTTP_URL="https://$FORGEJO_HOST/$FORGEJO_REPO"
	FORGEJO_CLONE_URL="$FORGEJO_HTTP_URL.git"

	if ! curl -sSfL "$FORGEJO_HTTP_URL" >/dev/null 2>&1; then
		echo "Repository $FORGEJO_HTTP_URL is not reachable."
		echo "Check URL or authentication."
		echo
		echo "Using fallback mirrors from $DEFAULT_JSON..."

		FORGEJO_MIRROR=false
		count=$(jq 'length' "$DEFAULT_JSON")

		for i in $(seq 1 $((count - 1))); do
			FALLBACK_IDX=$i
			FORGEJO_HOST=$(jq -r ".[$FALLBACK_IDX].host" $DEFAULT_JSON)
			FORGEJO_REPO=$(jq -r ".[$FALLBACK_IDX].repository" $DEFAULT_JSON)
			FORGEJO_HTTP_URL="https://$FORGEJO_HOST/$FORGEJO_REPO"
			FORGEJO_CLONE_URL="$FORGEJO_HTTP_URL.git"
			echo "Reaching repository $FORGEJO_HTTP_URL..."
			if curl -sSfL "$FORGEJO_HTTP_URL" >/dev/null 2>&1; then
				FORGEJO_MIRROR=true
				echo "FORGEJO_MIRROR=true" >> "$FORGEJO_LENV"
				break
			fi
		done
		if [ "$FORGEJO_MIRROR" != true ]; then
			echo "No reachable repository found in $DEFAULT_JSON" >&2
			exit 1
		fi
	fi

	case "$1" in
	master)
		FORGEJO_REF=$(jq -r '.ref' $PAYLOAD_JSON)
		FORGEJO_BRANCH=master

		FORGEJO_BEFORE=$(jq -r '.before' $PAYLOAD_JSON)
		echo "FORGEJO_BEFORE=$FORGEJO_BEFORE" >> "$FORGEJO_LENV"
		;;
	pull_request)
		FORGEJO_REF=$(jq -r '.ref' $PAYLOAD_JSON)
		FORGEJO_BRANCH=$(jq -r '.branch' $PAYLOAD_JSON)

		FORGEJO_PR_MERGE_BASE=$(jq -r '.merge_base' $PAYLOAD_JSON)
		FORGEJO_PR_NUMBER=$(jq -r '.number' $PAYLOAD_JSON)
		FORGEJO_PR_URL=$(jq -r '.url' $PAYLOAD_JSON)
		FORGEJO_PR_TITLE=$(.ci/common/field.py field="title" default_msg="No title provided" pull_request_number="$FORGEJO_PR_NUMBER")

		{
			echo "FORGEJO_PR_MERGE_BASE=$FORGEJO_PR_MERGE_BASE"
			echo "FORGEJO_PR_NUMBER=$FORGEJO_PR_NUMBER"
			echo "FORGEJO_PR_URL=$FORGEJO_PR_URL"
			echo "FORGEJO_PR_TITLE=$FORGEJO_PR_TITLE"
		} >> "$FORGEJO_LENV"
		;;
	tag)
		FORGEJO_REF=$(jq -r '.tag' $PAYLOAD_JSON)
		FORGEJO_BRANCH=stable
		;;
	push | test)
		FORGEJO_BRANCH=$(jq -r ".[$FALLBACK_IDX].branch" $DEFAULT_JSON)
		FORGEJO_REF=$(.ci/common/field.py field="sha")
		;;
	*)
		echo "Type: $1"
		echo "Supported types: master | pull_request | tag | push | test"
		exit 1
		;;
	esac

	{
		echo "FORGEJO_HOST=$FORGEJO_HOST"
		echo "FORGEJO_REPO=$FORGEJO_REPO"
		echo "FORGEJO_REF=$FORGEJO_REF"
		echo "FORGEJO_BRANCH=$FORGEJO_BRANCH"
		echo "FORGEJO_CLONE_URL=$FORGEJO_CLONE_URL"
	} >> "$FORGEJO_LENV"
}

# TODO: cleanup, cat-eof?
generate_summary() {
	echo "## Job Summary" >> "$GITHUB_STEP_SUMMARY"
	echo "- Triggered By: $1" >> "$GITHUB_STEP_SUMMARY"
	echo "- Commit: [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF)" >> "$GITHUB_STEP_SUMMARY"
	echo >> "$GITHUB_STEP_SUMMARY"

	if [ "$FORGEJO_MIRROR" = true ]; then
		echo "## Using mirror:" >> "$GITHUB_STEP_SUMMARY"
		echo "- Mirror URL: [\`$FORGEJO_HOST/$FORGEJO_REPO\`]($FORGEJO_CLONE_URL)" >> "$GITHUB_STEP_SUMMARY"
		echo >> "$GITHUB_STEP_SUMMARY"
	fi

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
		.ci/common/field.py field="body" default_msg="No changelog provided" pull_request_number="$FORGEJO_PR_NUMBER" >> "$GITHUB_STEP_SUMMARY"
		;;
	push | test)
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
	if ! curl -sSfL "$FORGEJO_CLONE_URL" >/dev/null 2>&1; then
		echo "Repository $FORGEJO_CLONE_URL is not reachable."
		echo "Check URL or authentication."
		echo
		exit 1
	fi

	git clone "$FORGEJO_CLONE_URL" eden

	if ! git -C eden checkout "$FORGEJO_REF"; then
		echo "Ref $FORGEJO_REF not found locally, trying to fetch..."
		git -C eden fetch origin "$FORGEJO_REF"
		git -C eden checkout "$FORGEJO_REF"
	fi

	echo "$FORGEJO_BRANCH" > eden/GIT-REFSPEC
	git -C eden rev-parse --short=10 HEAD >eden/GIT-COMMIT
	git -C eden describe --tags HEAD --abbrev=0 >eden/GIT-TAG || echo 'v0.0.3' >eden/GIT-TAG

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
--load-payload-env)
	load_payload_env
	;;
*)
	echo "Usage: $0 [--parse <type> | --summary <type> | --clone <type> | --load-payload-env]"
	echo "Supported types: master | pull_request | tag | push | test"
	;;
esac
