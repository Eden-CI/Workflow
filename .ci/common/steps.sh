#!/bin/sh -e

# Determine what steps to run in the release.
# This is done by setting the corresponding env variable to 1.

# Utilities.
success() {
	[ "$STATUS" = "success" ]
}

fj() {
	[ -n "$FJ_TOKEN" ]
}

gh() {
	[ -n "$GH_TOKEN" ]
}

dc() {
	[ -n "$DISCORD_WEBHOOK" ]
}

# Build status is only done on master or pull requests.
status() {
	case "$BUILD_ID" in
	master | pull_request)
		fj
		;;
	*)
		false
		;;
	esac
}

# We don't release on test builds.
release() {
	case "$BUILD_ID" in
	test)
		false
		;;
	*)
		success && gh
		;;
	esac
}

# Now set up the actual environment.
if status; then
	echo "SEND_STATUS=1"
fi

if release; then
	echo "SEND_RELEASE=1"
fi

if [ "$BUILD_ID" = pull_request ] && release; then
	echo "RELEASE_PR=1"
fi

if [ "$BUILD_ID" = "nightly" ] && dc; then
	echo "RELEASE_DISCORD=1"
fi

if [ "$BUILD_ID" = "tag" ] && fj && success; then
	echo "RELEASE_FJ=1"
fi