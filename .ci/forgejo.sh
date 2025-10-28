#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# payload manager for fj2ghook

FORGEJO_LENV=${FORGEJO_LENV:-"forgejo.env"}
touch "$FORGEJO_LENV"

parse_payload() {
	DEFAULT_JSON=".ci/default.json"
	RELEASE_JSON=".ci/release.json"
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

	# release.json defines targets for upload releases
	if [ ! -f "$RELEASE_JSON" ]; then
		echo "Warning: $RELEASE_JSON not found!"
		echo
		echo "You should set: 'build-id', 'host' and 'repository' on $RELEASE_JSON"
		echo "Skipping releases..."
	else
		RELEASE_MASTER_HOST=$(jq -r --arg id "master" '.[] | select(.["build-id"] == $id) | .host' $RELEASE_JSON)
		RELEASE_MASTER_REPO=$(jq -r --arg id "master" '.[] | select(.["build-id"] == $id) | .repository' $RELEASE_JSON)
		{
			echo "RELEASE_MASTER_HOST=$RELEASE_MASTER_HOST"
			echo "RELEASE_MASTER_REPO=$RELEASE_MASTER_REPO"
		} >> "$FORGEJO_LENV"
	fi

	# Forcefully set PGO target if not found
	RELEASE_PGO_HOST=$(jq -r --arg id "pgo" '( .[] | select(.["build-id"] == $id) | .host ) // "github.com"' $RELEASE_JSON)
	RELEASE_PGO_REPO=$(jq -r --arg id "pgo" '( .[] | select(.["build-id"] == $id) | .repository ) // "Eden-CI/PGO"' $RELEASE_JSON)

	# Payloads do not define host
	# This is just for verbosity
	FORGEJO_HOST=$(jq -r '.host // empty' $PAYLOAD_JSON)
	FORGEJO_REPO=$(jq -r '.repository // empty' $PAYLOAD_JSON)
	FORGEJO_CLONE_URL=$(jq -r '.clone_url // empty' $PAYLOAD_JSON)
	FORGEJO_BRANCH=$(jq -r '.branch // empty' $PAYLOAD_JSON)

	# NB: mirrors do not (generally) work for our purposes unless they magically can mirror everything in 10 seconds
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

	# Export those variables to be used by field.py
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

		# Pull Request is dependent of Master for comparassion
		if [ ! -z "$RELEASE_MASTER_REPO" ]; then
			RELEASE_PR_HOST=$(jq -r --arg id "pull_request" '.[] | select(.["build-id"] == $id) | .host' $RELEASE_JSON)
			RELEASE_PR_REPO=$(jq -r --arg id "pull_request" '.[] | select(.["build-id"] == $id) | .repository' $RELEASE_JSON)
			{
				echo "RELEASE_PR_HOST=$RELEASE_PR_HOST"
				echo "RELEASE_PR_REPO=$RELEASE_PR_REPO"
			} >> "$FORGEJO_LENV"
		fi
		;;
	tag)
		FORGEJO_REF=$(jq -r '.tag' $PAYLOAD_JSON)
		FORGEJO_BRANCH=stable

		RELEASE_TAG_HOST=$(jq -r --arg id "tag" '.[] | select(.["build-id"] == $id) | .host' $RELEASE_JSON)
		RELEASE_TAG_REPO=$(jq -r --arg id "tag" '.[] | select(.["build-id"] == $id) | .repository' $RELEASE_JSON)
		{
			echo "RELEASE_TAG_HOST=$RELEASE_TAG_HOST"
			echo "RELEASE_TAG_REPO=$RELEASE_TAG_REPO"
		} >> "$FORGEJO_LENV"
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
		echo "RELEASE_PGO_HOST=$RELEASE_PGO_HOST"
		echo "RELEASE_PGO_REPO=$RELEASE_PGO_REPO"
	} >> "$FORGEJO_LENV"
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
	git -C eden describe --tags HEAD --abbrev=0 > eden/GIT-TAG || echo 'v0.0.4-Workflow' > eden/GIT-TAG

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
--clone)
	clone_repository "$2"
	;;
*)
	cat << EOF
Usage: $0 [--parse <type> | --clone <type>]
Supported types: master | pull_request | tag | push | test

Commands:
    --parse: Parses an existing payload from payload.json, and creates
             a Forgejo environment file.

        If the payload doesn't exist, uses the latest master of the default host in default.json.

    --clone: Clones the target repository and checks out the correct reference (requires loaded environment).
EOF
	;;
esac
