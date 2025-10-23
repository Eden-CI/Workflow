#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# compiler handling
if [ "$COMPILER" = "clang" ]; then
	case "$PLATFORM" in
		(linux|freebsd)
			CLANG=clang
			CLANGPP=clang++
			;;
		(win)
			CLANG=clang-cl
			CLANGPP=clang-cl
			;;
		(*) ;;
	esac

	COMPILER_FLAGS+=(-DCMAKE_C_COMPILER="$CLANG" -DCMAKE_CXX_COMPILER="$CLANGPP")
fi

export COMPILER_FLAGS