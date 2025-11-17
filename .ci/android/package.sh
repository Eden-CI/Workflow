#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091

GITDATE="$(git show -s --date=short --format='%ad' | sed 's/-//g')"
GITREV="$(git show -s --format='%h')"
ROOTDIR="$PWD"
ARTIFACTS_DIR="artifacts"

. "$ROOTDIR"/.ci/common/project.sh

mkdir -p "$ARTIFACTS_DIR/"

case "$TARGET" in
	legacy) BUILD_FLAVOR=legacy ;;
	optimized) BUILD_FLAVOR=genshinSpoof ;;
	standard|*) BUILD_FLAVOR=mainline ;;
esac

REV_NAME="${PROJECT_REPO}-android-${GITDATE}-${GITREV}"
BUILD_TYPE_LOWER="release"
BUILD_TYPE_UPPER="Release"

find "$ROOTDIR/src/android/app/build/outputs" -type f -name "app*.a*"

cp "$ROOTDIR/src/android/app/build/outputs/apk/${BUILD_FLAVOR}/${BUILD_TYPE_LOWER}/app-${BUILD_FLAVOR}-${BUILD_TYPE_LOWER}.apk" \
	"$ARTIFACTS_DIR/${REV_NAME}.apk"

cp "$ROOTDIR/src/android/app/build/outputs/bundle/${BUILD_FLAVOR}${BUILD_TYPE_UPPER}/app-${BUILD_FLAVOR}-${BUILD_TYPE_LOWER}.aab" \
	"$ARTIFACTS_DIR/${REV_NAME}.aab"

ls -la "$ARTIFACTS_DIR/"
