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

b2() {
    [ -n "$B2_TOKEN" ] && [ -n "$B2_KEY" ]
}

# gh() {
# 	[ -n "$GH_TOKEN" ]
# }

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

release() {
	case "$BUILD_ID" in
	test)
		false
		;;
	*)
        # TODO(crueter): Better handling
		success && { b2 || fj; }
		;;
	esac
}

# Now set up the actual environment.
if status; then
	echo "SEND_STATUS=1"
fi

if [ "$BUILD_ID" = pull_request ] && release; then
	echo "RELEASE_PR=1"
fi

if [ "$BUILD_ID" = "nightly" ] && dc && release; then
	echo "RELEASE_DISCORD=1"
fi

if release; then
	echo "RELEASE_FJ=1"
fi

if [ "$BUILD_ID" = tag ] && release; then
    echo "RELEASE_TAG=1"
fi

# if release && [ "$BUILD_ID" != 'tag' ]; then
# 	echo "RELEASE_GH=1"
# fi