#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# credit: escary and hauntek

ROOTDIR=$PWD
BUILDDIR=${BUILDDIR:-build}
APP=eden.app

cd "$BUILDDIR/bin"

codesign --deep --force --verbose --sign - "$APP"

mkdir -p "$ROOTDIR"/artifacts
tar czf "$ROOTDIR"/artifacts/eden.tar.gz "$APP"
