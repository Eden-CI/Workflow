#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# credit: escary and hauntek

ROOTDIR="$PWD"

# shellcheck disable=SC1091
WORKFLOW_DIR=$(CDPATH='' cd -P -- "$(dirname -- "$0")/../.." && pwd)
. "$WORKFLOW_DIR/.ci/common/project.sh"

BUILDDIR="${BUILDDIR:-$ROOTDIR/build}"
ARTIFACTS_DIR="$ROOTDIR/artifacts"
APP="${PROJECT_REPO}.app"
: "${PACKAGE_TARGET:=eden-macos.tar.gz}"

cd "$BUILDDIR/bin"

codesign --deep --force --verbose --sign - "$APP"

mkdir -p "$ARTIFACTS_DIR"
tar czf "${ARTIFACTS_DIR}/${PACKAGE_TARGET}" "$APP"

echo "-- macOS package created at ${ARTIFACTS_DIR}/${PACKAGE_TARGET}"
