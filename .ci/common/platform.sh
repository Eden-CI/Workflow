#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# platform handling

uname -s

# special case for Windows (FU microsoft)
if [ ! -z "$VisualStudioVersion" ]; then
	PLATFORM=win
	STANDALONE=ON
	OPENSSL=ON
	FFMPEG=ON
	[ "$COMPILER" = "clang" ] && SUPPORTS_TARGETS=ON

	# LTO is completely broken on MSVC
	LTO=off
else
	case "$(uname -s)" in
	Linux*)
		PLATFORM=linux
		STANDALONE=OFF
		FFMPEG=ON
		OPENSSL=ON
		SUPPORTS_TARGETS=ON
		;;
	Darwin*)
		PLATFORM=macos
		STANDALONE=OFF
		FFMPEG=OFF
		OPENSSL=OFF
		export LIBVULKAN_PATH="/opt/homebrew/lib/libvulkan.1.dylib"
		;;
	CYGWIN* | MINGW* | MSYS*)
		PLATFORM=msys
		STANDALONE=ON
		OPENSSL=OFF
		FFMPEG=ON
		BUNDLED=OFF
		SUPPORTS_TARGETS=ON

		export PATH="$PATH:/mingw64/bin"

		# TODO: wtf is LTO doing
		;;
	FreeBSD*)
		PLATFORM=freebsd
		STANDALONE=OFF
		FFMPEG=OFF
		OPENSSL=ON
		SUPPORTS_TARGETS=ON
		;;
	*)
		echo "Unknown platform $(uname -s)"
		exit 1
		;;
	esac
fi

export PLATFORM
export STANDALONE
export LTO
export FFMPEG
export OPENSSL
export SUPPORTS_TARGETS
export BUNDLED

# TODO(crueter): document outputs n such
