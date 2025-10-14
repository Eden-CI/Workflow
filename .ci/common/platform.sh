#!/bin/sh -e

# platform handling
case "$(uname -s)" in
    Linux*)
		PLATFORM=linux
		PACKAGE=false
		;;
    Darwin*)
		PLATFORM=macos
		PACKAGE=false
		export LIBVULKAN_PATH="/opt/homebrew/lib/libvulkan.1.dylib"
		;;
    CYGWIN*|MSYS*|MINGW*)
		PLATFORM=win
		PACKAGE=true

		# LTO is completely broken on MSVC
		# TODO: msys2 has better lto
		LTO=off
		;;
    FreeBSD*)
		PLATFORM=freebsd
		PACKAGE=false
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