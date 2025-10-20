#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Unified CI helper for Forgejo > GitHub integration
# Supports: --parse, --summary, --clone

FORGEJO_LENV=${FORGEJO_LENV:-"forgejo.env"}
touch "$FORGEJO_LENV"

parse_payload() {
	DEFAULT_JSON="default.json"
	PAYLOAD_JSON="payload.json"

	if [ ! -f "$PAYLOAD_JSON" ]; then
		echo "null" > $PAYLOAD_JSON
	fi

	# default.json defines mirrors (should rarely be used unless Cloudflare does funny things)
	if [ ! -f "$DEFAULT_JSON" ]; then
		echo "Error: $DEFAULT_JSON not found!"
		echo
		echo "You should set: 'host', 'repository', 'clone_url', and 'branch' on $DEFAULT_JSON"
		exit 1
	fi

	# Payloads do not define host
	# This is just for verbosity
	FORGEJO_HOST=$(jq -r '.host // empty' $PAYLOAD_JSON)
	FORGEJO_REPO=$(jq -r '.repository // empty' $PAYLOAD_JSON)
	FORGEJO_CLONE_URL=$(jq -r '.clone_url // empty' $PAYLOAD_JSON)
	FORGEJO_BRANCH=$(jq -r '.branch // empty' $PAYLOAD_JSON)

	# NB: mirrors do not work for our purposes unless they magically can mirror everything in 10 seconds
	FALLBACK_IDX=0
	if [ -z "$FORGEJO_HOST" ]; then
		FORGEJO_HOST=$(jq -r ".[$FALLBACK_IDX].host" $DEFAULT_JSON)
	fi

	if [ -z "$FORGEJO_REPO" ]; then
		FORGEJO_REPO=$(jq -r ".[$FALLBACK_IDX].repository" $DEFAULT_JSON)
	fi

	[ -z "$FORGEJO_CLONE_URL" ] && FORGEJO_CLONE_URL="https://$FORGEJO_HOST/$FORGEJO_REPO.git"

	TRIES=0
	while ! curl -sSfL "$FORGEJO_CLONE_URL" >/dev/null 2>&1; do
		echo "Repository $FORGEJO_CLONE_URL is unreachable."
		echo "Check URL or authentication."

		TRIES=$((TRIES + 1))
		if [ "$TRIES" = 10 ]; then
			echo "Failed to reach $FORGEJO_CLONE_URL after ten tries. Exiting."
			exit 1
		fi

		sleep 5
		echo "Trying again..."
	done

	export FORGEJO_HOST
	export FORGEJO_BRANCH
	export FORGEJO_REPO

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

		FORGEJO_PR_NUMBER=$(jq -r '.number' $PAYLOAD_JSON)
		FORGEJO_PR_URL=$(jq -r '.url' $PAYLOAD_JSON)
		FORGEJO_PR_TITLE=$(.ci/common/field.py field="title" default_msg="No title provided" pull_request_number="$FORGEJO_PR_NUMBER")

		{
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
	echo "- Triggered by: $1" >> "$GITHUB_STEP_SUMMARY"
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
		echo "## Pull Request Summary" >> "$GITHUB_STEP_SUMMARY"
		echo "- Pull Request: #[${FORGEJO_PR_NUMBER}]($FORGEJO_PR_URL)" >> "$GITHUB_STEP_SUMMARY"
		echo "- Merge Base Commit: [\`$FORGEJO_PR_MERGE_BASE\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_PR_MERGE_BASE)" >> "$GITHUB_STEP_SUMMARY"
		echo >> "$GITHUB_STEP_SUMMARY"
		echo "## Pull Request Changelog Summary" >> "$GITHUB_STEP_SUMMARY"
		echo "$FORGEJO_PR_TITLE" >> "$GITHUB_STEP_SUMMARY"
		echo "" >> "$GITHUB_STEP_SUMMARY"
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

	TRIES=0
	while ! git clone "$FORGEJO_CLONE_URL" eden; do
		echo "Repository $FORGEJO_CLONE_URL is not reachable."
		echo "Check URL or authentication."

		TRIES=$((TRIES + 1))
		if [ "$TRIES" = 10 ]; then
			echo "Failed to clone $FORGEJO_CLONE_URL after ten tries. Exiting."
			exit 1
		fi

		sleep 5
		echo "Trying clone again..."
		rm -rf ./eden || true
	done

	if ! git -C eden checkout "$FORGEJO_REF"; then
		echo "Ref $FORGEJO_REF not found locally, trying to fetch..."
		git -C eden fetch --all
		git -C eden checkout "$FORGEJO_REF"
	fi

	echo "$FORGEJO_BRANCH" > eden/GIT-REFSPEC
	git -C eden rev-parse --short=10 HEAD > eden/GIT-COMMIT
	git -C eden describe --tags HEAD --abbrev=0 > eden/GIT-TAG || echo 'v0.0.3' > eden/GIT-TAG

	# slight hack: also add the merge base
	# <https://codeberg.org/forgejo/forgejo/issues/9601>
	FORGEJO_PR_MERGE_BASE=$(git -C eden merge-base master HEAD | cut -c1-10)
	echo "FORGEJO_PR_MERGE_BASE=$FORGEJO_PR_MERGE_BASE" >> "$FORGEJO_LENV"
	echo "FORGEJO_PR_MERGE_BASE=$FORGEJO_PR_MERGE_BASE" >> "$GITHUB_ENV"

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
	cat << EOF
Usage: $0 [--parse <type> | --summary <type> | --clone <type> | --load-payload-env]
Supported types: master | pull_request | tag | push | test

Commands:
    --load-payload-env: Load the payload environment from forgejo.env.

        Set FORGEJO_LENV to use a custom environment file.

    --parse: Parses an existing payload from payload.json, and creates
             a Forgejo environment file.

        If the payload doesn't exist, uses the latest master of the default host in default.json.

    --summary: Generates a summary for the payload (requires loaded environment).

        Output is placed in GITHUB_STEP_SUMMARY, usually this is for GitHub Actions

    --clone: Clones the target repository and checks out the correct reference (requires loaded environment).
EOF
	;;
esac
