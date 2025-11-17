#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# credit: escary and hauntek

ROOTDIR="$PWD"

# shellcheck disable=SC1091
. "$ROOTDIR"/ci/common/project.sh

BUILDDIR="${BUILDDIR:-build}"
ARTIFACTS_DIR="$ROOTDIR/artifacts"
APP="${PROJECT_REPO}.app"

cd "$BUILDDIR/bin"

codesign --deep --force --verbose --sign - "$APP"

mkdir -p "$ARTIFACTS_DIR"
tar czf "$ARTIFACTS_DIR/${PROJECT_REPO}.tar.gz" "$APP"

echo "MacOS package created at $ARTIFACTS_DIR/${PROJECT_REPO}.tar.gz"
