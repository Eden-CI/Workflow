#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# credit: escary and hauntek

ROOTDIR="$PWD"
BUILDDIR="$ROOTDIR/${BUILDDIR:-build}"
ARTIFACTS_DIR="$ROOTDIR/artifacts"
APP="eden.app"

cd "$BUILDDIR/bin"

codesign --deep --force --verbose --sign - "$APP"

mkdir -p "$ARTIFACTS_DIR"
tar czf "$ARTIFACTS_DIR/eden.tar.gz" "$APP"

echo "MacOS package created at $ARTIFACTS_DIR/eden.tar.gz"
