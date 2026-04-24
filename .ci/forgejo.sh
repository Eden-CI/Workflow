#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# payload manager for fj2ghook

# shellcheck disable=SC1091

ROOTDIR="$PWD"
. "$ROOTDIR/.ci/common/project.sh"

FORGEJO_LENV=${FORGEJO_LENV:-"forgejo.env"}
touch "$FORGEJO_LENV"

_field() {
	json="$1"
	build_id="$2"
	field="$3"

	jq -r --arg id "$build_id" \
		--arg field "$field" \
		'.[] | select(.["build-id"] == $id) | .[$field]' "$json"
}

b2_field() {
	_field "$ROOTDIR"/.ci/b2.json "$1" "$2"
}

fj_field() {
	_field "$ROOTDIR"/.ci/fj.json "$1" "$2"
}

parse_payload() {
	DEFAULT_JSON="$ROOTDIR/.ci/default.json"
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

	# hosts / repos
	RELEASE_PGO_HOST=github.com
	RELEASE_PGO_REPO=Eden-CI/PGO

	# B2 and Forgejo
	# shellcheck disable=SC2153
	case "$BUILD_ID" in
		test|push) _build=master ;;
		*) _build="$BUILD_ID" ;;
	esac

	B2_BUCKET=$(b2_field "$_build" bucket)
	B2_DIR=$(b2_field "$_build" directory)
	B2_URL=$(b2_field "$_build" url)
	B2_PUBLIC_URL=$(b2_field "$_build" public)

	if [ "$B2_DIR" = "null" ]; then
		B2_DIR=""
	fi

	RELEASE_HOST=$(fj_field "$_build" host)
	RELEASE_REPO=$(fj_field "$_build" repo)
	RELEASE_B2=$(fj_field "$_build" b2)

    MASTER_FJ_HOST=$(fj_field "master" host)
    MASTER_FJ_REPO=$(fj_field "master" repo)

	# Payloads do not define host
	# This is just for verbosity
	FORGEJO_HOST=$(jq -r '.host // empty' $PAYLOAD_JSON)
	FORGEJO_REPO=$(jq -r '.repository // empty' $PAYLOAD_JSON)
	FORGEJO_CLONE_URL=$(jq -r '.clone_url // empty' $PAYLOAD_JSON)
	FORGEJO_BRANCH=$(jq -r '.branch // empty' $PAYLOAD_JSON)

	# NB: mirrors do not (generally) work for our purposes
	# unless they magically can mirror everything in 10 seconds
	# The only exception to this is on test builds, where we usually don't need to have the most up-to-date code.

	# You can safely remove this if you don't have any regularly-updated mirrors.
	# shellcheck disable=SC2153
	case "$BUILD_ID" in
		test|push)
			FALLBACK_IDX=1
			;;
		*)
			FALLBACK_IDX=0
			;;
	esac
	if [ -z "$FORGEJO_HOST" ]; then
		FORGEJO_HOST=$(jq -r ".[$FALLBACK_IDX].host" "$DEFAULT_JSON")
	fi

	if [ -z "$FORGEJO_REPO" ]; then
		FORGEJO_REPO=$(jq -r ".[$FALLBACK_IDX].repository" "$DEFAULT_JSON")
	fi

	[ -z "$FORGEJO_CLONE_URL" ] && FORGEJO_CLONE_URL="https://$FORGEJO_HOST/$FORGEJO_REPO.git"

	TRIES=0
	TIMEOUT=5
	while ! curl -fL "$FORGEJO_CLONE_URL" >/dev/null 2>&1; do
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

		_tag="v${_timestamp}.${FORGEJO_REF}"
		_ref="${FORGEJO_REF}"

		_title="${PROJECT_PRETTYNAME} Master - ${FORGEJO_REF}"
		;;
	pull_request)
		FORGEJO_REF=$(jq -r '.ref' $PAYLOAD_JSON)
		FORGEJO_BRANCH=$(jq -r '.branch' $PAYLOAD_JSON)

		FORGEJO_PR_NUMBER=$(jq -r '.number' $PAYLOAD_JSON)
		FORGEJO_PR_URL=$(jq -r '.url' $PAYLOAD_JSON)
		FORGEJO_PR_TITLE=$(python3 "$ROOTDIR/.ci/common/field.py" field="title" default_msg="No title provided" pull_request_number="$FORGEJO_PR_NUMBER")

		{
			echo "FORGEJO_PR_NUMBER=$FORGEJO_PR_NUMBER"
			echo "FORGEJO_PR_URL=$FORGEJO_PR_URL"
			echo "FORGEJO_PR_TITLE=$FORGEJO_PR_TITLE"
		} >>"$FORGEJO_LENV"

		_tag="${FORGEJO_PR_NUMBER}-${FORGEJO_REF}"
		_ref="${FORGEJO_PR_NUMBER}-${FORGEJO_REF}"

		_title="${FORGEJO_PR_TITLE}"
		;;
	tag)
		FORGEJO_REF=$(jq -r '.tag' $PAYLOAD_JSON)
		FORGEJO_BRANCH=stable

		_tag="${FORGEJO_REF}"
		_ref="${FORGEJO_REF}"

		_title="${PROJECT_PRETTYNAME} ${FORGEJO_REF}"
		;;
	nightly)
		FORGEJO_BRANCH=$(jq -r ".[$FALLBACK_IDX].branch" "$DEFAULT_JSON")
		FORGEJO_REF=$("$ROOTDIR/.ci/common/field.py" field="sha")

		_tag="v${_timestamp}.${FORGEJO_REF}"
		_ref="${FORGEJO_REF}"

		# if last nightly was the same ref as this one, exit early
		# TODO(crueter): gh/fj handling
		FORGEJO_BEFORE=$(curl "https://$_host/api/v1/repos/$_repo/releases/latest" | jq -r '.tag_name' | cut -d'.' -f2)

		if [ "$FORGEJO_BEFORE" = "$_ref" ]; then
			echo "current ref $_ref is same as last nightly $FORGEJO_BEFORE, skipping"
			exit 1
		fi

		_title="${PROJECT_PRETTYNAME} Nightly - $(date +"%b %d %Y")"
		;;
	push | test)
		FORGEJO_BRANCH=$(jq -r ".[$FALLBACK_IDX].branch" "$DEFAULT_JSON")
		FORGEJO_REF=$("$ROOTDIR/.ci/common/field.py" field="sha")

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
		echo "FORGEJO_BEFORE=$FORGEJO_BEFORE"

		echo "RELEASE_HOST=$RELEASE_HOST"
		echo "RELEASE_REPO=$RELEASE_REPO"
        echo "RELEASE_B2=$RELEASE_B2"

        echo "B2_BUCKET=$B2_BUCKET"
        echo "B2_DIR=$B2_DIR"
        echo "B2_URL=$B2_URL"
        echo "B2_PUBLIC_URL=$B2_PUBLIC_URL"

		echo "RELEASE_PGO_HOST=$RELEASE_PGO_HOST"
		echo "RELEASE_PGO_REPO=$RELEASE_PGO_REPO"

		echo "GITHUB_TAG=$_tag"
		echo "GITHUB_TITLE=$_title"
		echo "ARTIFACT_REF=$_ref"
		echo "GITHUB_DOWNLOAD=https://$RELEASE_HOST/$RELEASE_REPO/releases/download"

		echo "MASTER_RELEASE_URL=https://$MASTER_FJ_HOST/$MASTER_FJ_REPO/releases"

		# Package targets need this
		echo "PROJECT_PRETTYNAME=$PROJECT_PRETTYNAME"
	} >>"$FORGEJO_LENV"
}

clone_repository() {
	if ! curl -fL "$FORGEJO_CLONE_URL" >/dev/null 2>&1; then
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
	{ git describe --tags HEAD --abbrev=0 || cat "$ROOTDIR/WORKFLOW-TAG"; } > GIT-TAG

	if [ "$1" = "tag" ]; then
		cp GIT-TAG GIT-RELEASE
	fi

	FORGEJO_PR_MERGE_BASE=$(git merge-base master HEAD | cut -c1-10)
	FORGEJO_LONGSHA=$(git rev-parse "$FORGEJO_REF")

	if [ "$1" = "nightly" ]; then
		# construct changelog
		_url="https://$FORGEJO_HOST/$FORGEJO_REPO"
		_format="- %s [\`%h\`]($_url/commit/%H)%n  - Committed on %as by %an %(trailers:key=Reviewed-on,valueonly=true,separator=)"
		_find="Committed on (.+) by (.+) .+/pulls/([0-9]+)"
		_replace="PR #[\3](https://git.eden-emu.dev/eden-emu/eden/pulls/\3) merged on \1 by \2"

		{
			echo "## Changelog"
			echo
			git log "$FORGEJO_BEFORE..$FORGEJO_REF" --pretty="$_format" | sed -E "s|$_find|$_replace|"
			echo
		} > "$ROOTDIR"/nightly-changelog.md
	fi

	cd ..

	# slight hack: also add the merge base
	# <https://codeberg.org/forgejo/forgejo/issues/9601>
	echo "FORGEJO_PR_MERGE_BASE=$FORGEJO_PR_MERGE_BASE" >>"$FORGEJO_LENV"
	echo "FORGEJO_PR_MERGE_BASE=$FORGEJO_PR_MERGE_BASE" >>"$GITHUB_ENV"

	echo "FORGEJO_LONGSHA=$FORGEJO_LONGSHA" >>"$FORGEJO_LENV"
	echo "FORGEJO_LONGSHA=$FORGEJO_LONGSHA" >>"$GITHUB_ENV"
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
Supported types: master | pull_request | tag | push | test | nightly

Commands:
    --parse: Parses an existing payload from payload.json, and creates
             a Forgejo environment file.

        If the payload doesn't exist, uses the latest master of the default host in default.json.

    --clone: Clones the target repository and checks out the correct reference (requires loaded environment).
EOF
	;;
esac
