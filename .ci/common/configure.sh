#!/bin/bash -ex

# The master CMake configurator.
# Environment variables:
# - BUILDDIR: build directory (default build)
# - DEVEL: set to true to disable update checker and add "nightly" to app name
# - LTO: Turn LTO on/off (forced OFF on Windows)
# - TARGET: Change the build target (see targets.sh) -- Linux/clang-cl only

# - BUILD_TYPE: build type (default Release)
# - BUNDLE_QT: Use bundled Qt (default OFF)
# - USE_MULTIMEDIA: Enable Qt Multimedia (default OFF)
# - USE_WEBENGINE: Enable Qt WebEngine (default OFF)
# - CCACHE: Enable CCache (default OFF)

# shellcheck disable=SC1091

BUILDDIR="${BUILDDIR:-build}"

# annoying
if [ "$DEVEL" = "true" ]; then
	UPDATES=OFF
else
	UPDATES=ON
fi

# platform handling
. .ci/common/platform.sh

# sdl/arch handling (targets)
. .ci/common/targets.sh

# Determine if we need to build standalone executables, bundle deps, etc.
if [ "$PACKAGE" = "true" ]; then
	BUNDLE=OFF
	FFMPEG=OFF
else
	BUNDLE=ON
fi

case "$PLATFORM" in
	(freebsd)
		PLATFORM_FLAGS=(
			-DYUZU_USE_CPM=ON
			-DENABLE_WEB_SERVICE=OFF
		)
		;;
	(*) ;;
esac

# Flags all targets use
COMMON_FLAGS=(
	# DO not build tests
    -DBUILD_TESTING=OFF

	# build type
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE:-Release}" \

	# Qt
    -DYUZU_USE_BUNDLED_QT="${BUNDLE_QT:-OFF}"
    -DYUZU_USE_QT_MULTIMEDIA="${USE_MULTIMEDIA:-OFF}"
    -DYUZU_USE_QT_WEB_ENGINE="${USE_WEBENGINE:-OFF}"
    -DENABLE_QT_TRANSLATION=ON
    -DENABLE_QT_UPDATE_CHECKER="${UPDATES:-ON}"

	# misc
    -DUSE_CCACHE="${CCACHE:-OFF}"
    -DUSE_DISCORD_PRESENCE=ON

	# LTO
	-DDYNARMIC_ENABLE_LTO="${LTO:-ON}"
    -DYUZU_ENABLE_LTO="${LTO:-ON}"

	# many distros do not package sirit, so let's bundle it anyways
    -DYUZU_USE_BUNDLED_SIRIT=ON

	# Bundled stuff (only if not building for a pkg)
	-DYUZU_USE_BUNDLED_FFMPEG="${FFMPEG:-ON}"
    -DYUZU_USE_BUNDLED_OPENSSL="${BUNDLE:-ON}"
    -DYUZU_DISABLE_LLVM=ON

	# macos only
	-DYUZU_USE_BUNDLED_MOLTENVK=ON

	# packaging stuff
	-DCMAKE_INSTALL_PREFIX=/usr
	-DYUZU_CMD="${PACKAGE:-OFF}"
	-DYUZU_ROOM_STANDALONE="${PACKAGE:-OFF}"
)

# cmd line stuff
EXTRA_ARGS=("$@")

# aggregate
CMAKE_FLAGS=(
	"${COMMON_FLAGS[@]}"
	"${SDL_FLAGS[@]}"
	"${ARCH_CMAKE[@]}"
	"${COMPILER_FLAGS[@]}"
	"${PLATFORM_FLAGS[@]}"
	"${EXTRA_ARGS[@]}"
)

cmake -S . -B "${BUILDDIR}" -G Ninja "${CMAKE_FLAGS[@]}"