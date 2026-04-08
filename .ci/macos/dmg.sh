#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

ROOTDIR="$PWD"

# shellcheck disable=SC1091
. "$ROOTDIR/.ci/common/project.sh"

BUILDDIR="${BUILDDIR:-$ROOTDIR/build}"
ARTIFACTS_DIR="$ROOTDIR/artifacts"
APP="${PROJECT_REPO}.app"
APPDIR="${BUILDDIR}/bin"

ARTIFACT="${ARTIFACTS_DIR}/${PROJECT_PRETTYNAME}-macOS-${ARTIFACT_REF}.dmg"
VOLUME_NAME="${PROJECT_PRETTYNAME} ${ARTIFACT_REF} Installer"

codesign --deep --force --verbose --sign - "$APPDIR/$APP"

# No clue why this is here
rm -rf "$APPDIR"/send-presence.app

mkdir -p "$ARTIFACTS_DIR"

sudo create-dmg \
  --volname "${VOLUME_NAME}" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 128 \
  --icon "${APP}" 200 190 \
  --hide-extension "${APP}" \
  --app-drop-link 600 185 \
  "${ARTIFACT}" \
  "${APPDIR}"

ls -lh

echo "-- macOS package created at $ARTIFACTS_DIR/$ARTIFACT"
