#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# compiler handling
if [ "$COMPILER" = "clang" ]; then
	LD=lld

	case "$PLATFORM" in
	linux | freebsd | msys)
		CLANG=clang
		CLANGPP=clang++
		;;
	macos)
		prefix="$(brew --prefix llvm)/bin"
		CLANG="${prefix}/clang"
		CLANGPP="${prefix}/clang++"
		LD="${prefix}/ld.lld"
		# maybe not needed
		COMPILER_FLAGS+=(-DCMAKE_OSX_SYSROOT="$(xcrun --show-sdk-path)")
		;;
	win)
		CLANG=clang-cl
		CLANGPP=clang-cl
		;;
	*) ;;
	esac

	COMPILER_FLAGS+=(-DCMAKE_C_COMPILER="$CLANG" -DCMAKE_CXX_COMPILER="$CLANGPP" -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=$LD")
elif [ "$COMPILER" = "msvc" ]; then
	# bruh
	COMPILER_FLAGS+=(-DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl)
fi

export COMPILER_FLAGS
