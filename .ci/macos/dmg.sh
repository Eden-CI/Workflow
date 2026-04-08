#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

ROOTDIR="$PWD"

# shellcheck disable=SC1091
. "$ROOTDIR/.ci/common/project.sh"

BUILDDIR="${BUILDDIR:-$ROOTDIR/build}"
ARTIFACTS_DIR="$ROOTDIR/artifacts"
APP="${PROJECT_REPO}.app"

ARTIFACT="${PROJECT_PRETTYNAME}-macOS-${ARTIFACT_REF}.dmg"

cd "$BUILDDIR/bin"

codesign --deep --force --verbose --sign - "$APP"

mkdir -p "$ARTIFACTS_DIR"

curl -L https://github.com/create-dmg/create-dmg/raw/refs/heads/master/create-dmg -O
chmod a+x ./create-dmg

sudo ./create-dmg \
  --volname "${PROJECT_PRETTYNAME} ${ARTIFACT_REF} Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 128 \
  --icon "${APP}" 200 190 \
  --hide-extension "${APP}" \
  --app-drop-link 600 185 \
  "${ARTIFACT}" \
  "${BUILDDIR}/bin"

ls -lh

mv "${ARTIFACT}.dmg" "$ARTIFACTS_DIR"

echo "-- macOS package created at $ARTIFACT"
