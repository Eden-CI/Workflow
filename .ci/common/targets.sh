#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

SDL_FLAGS=(
	-DYUZU_USE_BUNDLED_SDL3=ON
	-DYUZU_USE_BUNDLED_SDL2=ON
)

OPENSSL=external

# only clang and gcc support this
if [ "$PLATFORM" = win ]; then
	OPENSSL=bundled
elif [ -n "$SUPPORTS_TARGETS" ]; then
	case "$TARGET" in
		legacy)
			echo "Making amd64 generic build of ${PROJECT_PRETTYNAME}"
			ARCH_FLAGS="-march=x86-64 -mtune=generic"
			ARCH=legacy
			OPENSSL=bundled
			;;
		amd64)
			echo "Making amd64-v3 optimized build of ${PROJECT_PRETTYNAME}"
			ARCH_FLAGS="-march=x86-64-v3 -mtune=generic"
			ARCH="amd64"
			BUILD_TARGET=amd64
			;;
		steamdeck|zen2)
			echo "Making Steam Deck (Zen 2) optimized build of ${PROJECT_PRETTYNAME}"
			ARCH_FLAGS="-march=znver2 -mtune=znver2"
			ARCH="steamdeck"
			;;
		rog-ally|allyx|zen4)
			echo "Making ROG Ally X (Zen 4) optimized build of ${PROJECT_PRETTYNAME}"
			ARCH_FLAGS="-march=znver4 -mtune=znver4"
			ARCH="rog-ally-x"
			BUILD_TARGET=rog-ally
			;;
		aarch64|arm64)
			echo "Making armv8-a build of ${PROJECT_PRETTYNAME}"
			ARCH_FLAGS="-march=armv8-a -mtune=generic"
			ARCH=aarch64
			OPENSSL=bundled
			;;
		armv9)
			echo "Making armv9-a build of ${PROJECT_PRETTYNAME}"
			ARCH_FLAGS="-march=armv9-a -mtune=generic"
			ARCH=armv9
			;;
		# Special target: package-{amd64,aarch64}
		# In the "package" target we WANT standalone executables
		# and want to target generic architectures
		package-amd64)
			echo "Making package-friendly amd64 build of ${PROJECT_PRETTYNAME}"
			ARCH_FLAGS="-march=x86-64 -mtune=generic"
			STANDALONE=ON
			PACKAGE=true
			FFMPEG=OFF
			OPENSSL=system
			UPDATES=ON
			;;
		package-aarch64)
			echo "Making package-friendly aarch64 build of ${PROJECT_PRETTYNAME}"
			ARCH_FLAGS="-march=armv8-a -mtune=generic"
			STANDALONE=ON
			PACKAGE=true
			FFMPEG=OFF
			OPENSSL=system
			UPDATES=ON

			# apparently gcc-arm64 on ubuntu dislikes lto
			LTO=OFF
			;;
		m1|apple)
			echo "Making Apple M1 build of ${PROJECT_PRETTYNAME}"
			ARCH_FLAGS="-march=apple-m1 -mtune=apple-m1"
			ARCH=m1
			OPENSSL=bundled
			;;
		*)
			echo "Invalid target $TARGET specified"
			exit 1
			;;
	esac

	ARCH_FLAGS="${ARCH_FLAGS} -O3"
	[ "$PLATFORM" = "linux" ] && ARCH_FLAGS="${ARCH_FLAGS} -pipe"

	# For PGO, we fetch profdata and add it to our flags
	if [ "$PGO_TARGET" = "pgo" ]; then
		echo "Creating PGO build"

		CCACHE=OFF

		PROFDATA="$PWD/${PROJECT_REPO}.profdata"
		[ -f "$PROFDATA" ] && rm -f "$PROFDATA"
		curl -fL https://"$RELEASE_PGO_HOST"/"$RELEASE_PGO_REPO/releases/latest/download/${PROJECT_REPO}.profdata" > "$PROFDATA"
		[ ! -f "$PROFDATA" ] && (echo "PGO data failed to download" ; exit 1)
		command -v cygpath >/dev/null 2>&1 && PROFDATA="$(cygpath -m "$PROFDATA")"
		ARCH_FLAGS="${ARCH_FLAGS} -fprofile-use=$PROFDATA -Wno-backend-plugin -Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date"
	fi
fi

if [ "$STEAMDECK" = "true" ]; then
	SDL_FLAGS=(
		-DYUZU_SYSTEM_PROFILE=steamdeck
		-DYUZU_USE_EXTERNAL_SDL2=ON
	)
fi

# Package targets should use system sdl3
# Mostly to test comp
if [ "$PACKAGE" = "true" ]; then
	SDL_FLAGS=(-DYUZU_USE_BUNDLED_SDL3=OFF)
fi

[ -n "$ARCH_FLAGS" ] && ARCH_CMAKE+=(-DCMAKE_C_FLAGS="${ARCH_FLAGS}" -DCMAKE_CXX_FLAGS="${ARCH_FLAGS}")

case "$OPENSSL" in
	system) ARCH_CMAKE+=(-DYUZU_USE_BUNDLED_OPENSSL=OFF -DOpenSSL_FORCE_SYSTEM=ON) ;;
	bundled) ARCH_CMAKE+=(-DYUZU_USE_BUNDLED_OPENSSL=ON) ;;
	external) ARCH_CMAKE+=(-DYUZU_USE_BUNDLED_OPENSSL=OFF -DOpenSSL_FORCE_BUNDLED=ON) ;;
esac

export ARCH_CMAKE
export SDL_FLAGS
export STANDALONE
export ARCH
export OPENSSL
export FFMPEG
export LTO
export CCACHE
export UPDATES
export BUILD_TARGET