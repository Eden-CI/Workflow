#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

ROOTDIR="$PWD"
BUILDDIR="${BUILDDIR:-build}"

cmake -S "$ROOTDIR" -B "$BUILDDIR" -G "Ninja" -DYUZU_STATIC_ROOM=ON "$@"
