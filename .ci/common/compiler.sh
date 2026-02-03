#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

if [ -z "${BASH_VERSION:-}" ]; then
    echo "error: This script MUST be run with bash"
    exit 1
fi

# compiler handling
if [ "$COMPILER" = "clang" ]; then
	case "$PLATFORM" in
		(linux|freebsd|msys)
			CLANG=clang
			CLANGPP=clang++
			;;
		(win)
			CLANG=clang-cl
			CLANGPP=clang-cl
			;;
		(*) ;;
	esac

	COMPILER_FLAGS+=(-DCMAKE_C_COMPILER="$CLANG" -DCMAKE_CXX_COMPILER="$CLANGPP" -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld")
fi

export COMPILER_FLAGS