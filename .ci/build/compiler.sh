#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# scarletnx only works on clang (android is also clang)
if [ "$COMPILER" = clang ] || [ "$PLATFORM" = android ]; then
	if [ "$PLATFORM" = msys ]; then
		llvm-config --libs
		llvm-config --prefix

		ls -l /$MYSTEM/lib/libLLVM*
	fi

	COMPILER_FLAGS+=(-DENABLE_SCARLETNX=ON)
fi

# compiler handling
if [ "$COMPILER" = "clang" ]; then
	case "$PLATFORM" in
	linux | freebsd | msys)
		CLANG=clang
		CLANGPP=clang++
		;;
	macos)
		prefix="$(brew --prefix llvm)/bin"
		CLANG="${prefix}/clang"
		CLANGPP="${prefix}/clang++"
		# maybe not needed
		COMPILER_FLAGS+=(-DCMAKE_OSX_SYSROOT="$(xcrun --show-sdk-path)")
		COMPILER_FLAGS+=(-DSNX_LLVM_CONFIG="$(brew --prefix llvm)/bin/llvm-config")
		;;
	*) ;;
	esac

	COMPILER_FLAGS+=(-DCMAKE_C_COMPILER="$CLANG" -DCMAKE_CXX_COMPILER="$CLANGPP" -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld")
elif [ "$COMPILER" = "msvc" ]; then
	# bruh
	COMPILER_FLAGS+=(-DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl)
elif [ "$COMPILER" = "gcc-16" ]; then
	# KILL YOURSELF
	COMPILER_FLAGS+=(-DCMAKE_C_COMPILER=gcc-16 -DCMAKE_CXX_COMPILER=g++-16)
fi

export COMPILER_FLAGS
