#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# platform handling
case "$(uname -s)" in
	Linux*)
		PLATFORM=linux
		STANDALONE=OFF
		FFMPEG=ON
		OPENSSL=ON
		;;
	Darwin*)
		PLATFORM=macos
		STANDALONE=OFF
		FFMPEG=OFF
		OPENSSL=OFF
		export LIBVULKAN_PATH="/opt/homebrew/lib/libvulkan.1.dylib"
		;;
	CYGWIN*|MSYS*|MINGW*)
		PLATFORM=win
		STANDALONE=ON
		OPENSSL=ON
		FFMPEG=ON

		# LTO is completely broken on MSVC
		# TODO: msys2 has better lto
		LTO=off
		;;
	FreeBSD*)
		PLATFORM=freebsd
		STANDALONE=OFF
		FFMPEG=OFF
		OPENSSL=ON
		;;
	*)
		echo "Unknown platform $(uname -s)"
		exit 1 ;;
esac

export PLATFORM
export STANDALONE
export LTO
export FFMPEG
export OPENSSL
