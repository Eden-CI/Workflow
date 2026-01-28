#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# credit: escary and hauntek

ROOTDIR="$PWD"

BUILDDIR="${BUILDDIR:-build}"
ARTIFACTS_DIR="$ROOTDIR/artifacts"
BINARY="eden-room-$ARCH-unknown-linux-musl"

mkdir -p "$ARTIFACTS_DIR"

mv "$BUILDDIR"/bin/eden-room "$ARTIFACTS_DIR"/"$BINARY"