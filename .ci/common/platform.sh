#!/bin/sh -e

# platform handling
case "$(uname -s)" in
    Linux*)
		PLATFORM=linux
		PACKAGE=false
		FFMPEG=ON
		;;
    Darwin*)
		PLATFORM=macos
		PACKAGE=false
		FFMPEG=OFF
		export LIBVULKAN_PATH="/opt/homebrew/lib/libvulkan.1.dylib"
		;;
    CYGWIN*|MSYS*|MINGW*)
		PLATFORM=win
		PACKAGE=true
		FFMPEG=ON

		# LTO is completely broken on MSVC
		# TODO: msys2 has better lto
		LTO=off
		;;
    FreeBSD*)
		PLATFORM=freebsd
		PACKAGE=false
		FFMPEG=OFF
		UPDATES=OFF
		;;
    *)
		echo "Unknown platform $(uname -s)"
		exit 1 ;;
esac

export PLATFORM
export PACKAGE
export LTO
export UPDATES
export FFMPEG