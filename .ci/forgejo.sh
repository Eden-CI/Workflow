#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# payload manager for fj2ghook

# shellcheck disable=SC1091

ROOTDIR="$PWD"
. "$ROOTDIR"/.ci/common/project.sh

FORGEJO_LENV=${FORGEJO_LENV:-"forgejo.env"}
touch "$FORGEJO_LENV"

_release_field() {
	build_id="$1"
	field="$2"

	jq -r --arg id "$build_id" \
		--arg field "$field" \
		'.[] | select(.["build-id"] == $id) | .[$field]' "$RELEASE_JSON"
}

parse_payload() {
	DEFAULT_JSON=".ci/default.json"
	RELEASE_JSON=".ci/release.json"
	PAYLOAD_JSON="payload.json"

	if [ ! -f "$PAYLOAD_JSON" ]; then
		echo "null" >$PAYLOAD_JSON
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
		echo "Error: $RELEASE_JSON not found!"
		echo
		echo "You should set: 'build-id', 'host' and 'repository' on $RELEASE_JSON"
		exit 1
	fi

	# hosts / repos
	RELEASE_PGO_HOST=$(_release_field "pgo" "host")
	RELEASE_PGO_REPO=$(_release_field "pgo" "repository")

	RELEASE_MASTER_HOST=$(_release_field "master" "host")
	RELEASE_MASTER_REPO=$(_release_field "master" "repository")

	RELEASE_PR_HOST=$(_release_field "pull_request" "host")
	RELEASE_PR_REPO=$(_release_field "pull_request" "repository")

	RELEASE_TAG_HOST=$(_release_field "tag" "host")
	RELEASE_TAG_REPO=$(_release_field "tag" "repository")

	RELEASE_NIGHTLY_HOST=$(_release_field "nightly" "host")
	RELEASE_NIGHTLY_REPO=$(_release_field "nightly" "repository")

	# Payloads do not define host
	# This is just for verbosity
	FORGEJO_HOST=$(jq -r '.host // empty' $PAYLOAD_JSON)
	FORGEJO_REPO=$(jq -r '.repository // empty' $PAYLOAD_JSON)
	FORGEJO_CLONE_URL=$(jq -r '.clone_url // empty' $PAYLOAD_JSON)
	FORGEJO_BRANCH=$(jq -r '.branch // empty' $PAYLOAD_JSON)

	# NB: mirrors do not (generally) work for our purposes
	# unless they magically can mirror everything in 10 seconds
	FALLBACK_IDX=0
	if [ -z "$FORGEJO_HOST" ]; then
		FORGEJO_HOST=$(jq -r ".[$FALLBACK_IDX].host" $DEFAULT_JSON)
	fi

	if [ -z "$FORGEJO_REPO" ]; then
		FORGEJO_REPO=$(jq -r ".[$FALLBACK_IDX].repository" $DEFAULT_JSON)
	fi

	[ -z "$FORGEJO_CLONE_URL" ] && FORGEJO_CLONE_URL="https://$FORGEJO_HOST/$FORGEJO_REPO.git"

	TRIES=0
	TIMEOUT=5
	while ! curl -sSfL "$FORGEJO_CLONE_URL" >/dev/null 2>&1; do
		echo "Repository $FORGEJO_CLONE_URL is unreachable."
		echo "Check URL or authentication."

		TRIES=$((TRIES + 1))
		if [ "$TRIES" = 10 ]; then
			echo "Failed to reach $FORGEJO_CLONE_URL after ten tries. Exiting."
			exit 1
		fi

		sleep "$TIMEOUT"
		echo "Trying again..."
		TIMEOUT=$((TIMEOUT * 2))
	done

	# Export those variables to be used by field.py
	export FORGEJO_HOST
	export FORGEJO_BRANCH
	export FORGEJO_REPO

	_timestamp=$(date +%s)

	case "$1" in
	master)
		FORGEJO_REF=$(jq -r '.ref' $PAYLOAD_JSON)
		FORGEJO_BRANCH=master

		FORGEJO_BEFORE=$(jq -r '.before' $PAYLOAD_JSON)
		echo "FORGEJO_BEFORE=$FORGEJO_BEFORE" >>"$FORGEJO_LENV"

		_host="$RELEASE_MASTER_HOST"
		_repo="$RELEASE_MASTER_REPO"

		_tag="v${_timestamp}.${FORGEJO_REF}"
		_ref="${FORGEJO_REF}"

		_title="${PROJECT_PRETTYNAME} Master - ${FORGEJO_REF}"
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
		} >>"$FORGEJO_LENV"

		_host="$RELEASE_PR_HOST"
		_repo="$RELEASE_PR_REPO"

		_tag="${FORGEJO_PR_NUMBER}-${FORGEJO_REF}"
		_ref="${FORGEJO_PR_NUMBER}-${FORGEJO_REF}"

		_title="${FORGEJO_PR_TITLE}"
		;;
	tag)
		FORGEJO_REF=$(jq -r '.tag' $PAYLOAD_JSON)
		FORGEJO_BRANCH=stable

		_host="$RELEASE_TAG_HOST"
		_repo="$RELEASE_TAG_REPO"

		_tag="${FORGEJO_REF}"
		_ref="${FORGEJO_REF}"

		_title="${PROJECT_PRETTYNAME} ${FORGEJO_REF}"
		;;
	nightly)
		# TODO(crueter): date-based referencing
		FORGEJO_REF=$(jq -r '.ref' $PAYLOAD_JSON)
		FORGEJO_BRANCH=nightly

		_host="$RELEASE_NIGHTLY_HOST"
		_repo="$RELEASE_NIGHTLY_REPO"

		_tag="v${_timestamp}.${FORGEJO_REF}"
		_ref="${FORGEJO_REF}"

		_title="Nightly Build - ${FORGEJO_REF}"
		;;
	push | test)
		FORGEJO_BRANCH=$(jq -r ".[$FALLBACK_IDX].branch" $DEFAULT_JSON)
		FORGEJO_REF=$(.ci/common/field.py field="sha")

		_host="$RELEASE_NIGHTLY_HOST"
		_repo="$RELEASE_NIGHTLY_REPO"

		_tag="v${_timestamp}.${FORGEJO_REF}"
		_ref="${FORGEJO_REF}"
		_title="Continuous Build - $FORGEJO_REF"
		;;
	*)
		echo "Type: $1"
		echo "Supported types: master | pull_request | tag | push | test | nightly"
		exit 1
		;;
	esac

	{
		echo "FORGEJO_HOST=$FORGEJO_HOST"
		echo "FORGEJO_REPO=$FORGEJO_REPO"
		echo "FORGEJO_REF=$FORGEJO_REF"
		echo "FORGEJO_BRANCH=$FORGEJO_BRANCH"
		echo "FORGEJO_CLONE_URL=$FORGEJO_CLONE_URL"

		# TODO: get rid of host
		echo "RELEASE_HOST=$_host"
		echo "RELEASE_REPO=$_repo"

		echo "RELEASE_PGO_HOST=$RELEASE_PGO_HOST"
		echo "RELEASE_PGO_REPO=$RELEASE_PGO_REPO"

		echo "GITHUB_TAG=$_tag"
		echo "GITHUB_TITLE=$_title"
		echo "ARTIFACT_REF=$_ref"
		echo "GITHUB_DOWNLOAD=https://$_host/$_repo/releases/download"

		echo "MASTER_RELEASE_URL=https://$RELEASE_MASTER_HOST/$RELEASE_MASTER_REPO/releases"

		# Package targets need this
		echo "PROJECT_PRETTYNAME=$PROJECT_PRETTYNAME"
	} >>"$FORGEJO_LENV"
}

clone_repository() {
	if ! curl -sSfL "$FORGEJO_CLONE_URL" >/dev/null 2>&1; then
		echo "Repository $FORGEJO_CLONE_URL is not reachable."
		echo "Check URL or authentication."
		echo
		exit 1
	fi

	TRIES=0
	while ! git clone "$FORGEJO_CLONE_URL" "$PROJECT_REPO"; do
		echo "Repository $FORGEJO_CLONE_URL is not reachable."
		echo "Check URL or authentication."

		TRIES=$((TRIES + 1))
		if [ "$TRIES" = 10 ]; then
			echo "Failed to clone $FORGEJO_CLONE_URL after ten tries. Exiting."
			exit 1
		fi

		sleep 5
		echo "Trying clone again..."
		rm -rf "./${PROJECT_REPO}" || true
	done

	cd "$PROJECT_REPO"

	if ! git checkout "$FORGEJO_REF"; then
		echo "Ref $FORGEJO_REF not found locally, trying to fetch..."
		git fetch --all
		git checkout "$FORGEJO_REF"
	fi

	echo "$FORGEJO_BRANCH" > GIT-REFSPEC
	git rev-parse --short=10 HEAD > GIT-COMMIT
	{ git describe --tags HEAD --abbrev=0 || echo 'v0.1.0-Workflow'; } > GIT-TAG

	# slight hack: also add the merge base
	# <https://codeberg.org/forgejo/forgejo/issues/9601>
	FORGEJO_PR_MERGE_BASE=$(git merge-base master HEAD | cut -c1-10)
	echo "FORGEJO_PR_MERGE_BASE=$FORGEJO_PR_MERGE_BASE" >>"$FORGEJO_LENV"
	echo "FORGEJO_PR_MERGE_BASE=$FORGEJO_PR_MERGE_BASE" >>"$GITHUB_ENV"

	if [ "$1" = "tag" ]; then
		cp GIT-TAG GIT-RELEASE
	fi

	cd ..
}

case "$1" in
--parse)
	parse_payload "$2"
	;;
--clone)
	clone_repository "$2"
	;;
*)
	cat <<EOF
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
