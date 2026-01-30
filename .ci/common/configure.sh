#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

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

ROOTDIR="$PWD"
BUILDDIR="${BUILDDIR:-build}"
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC2153
echo "Build ID: $BUILD_ID"

# check if it's called eden dir
if [ ! -f "$ROOTDIR/CMakeLists.txt" ]; then
	echo "error: no CMakeLists.txt found in ROOTDIR ($ROOTDIR)."
	echo "Make sure you are running this script from the root of the Eden repository."
	exit 1
fi

# check if common script folder is on Workflow
if [ ! -d "$WORKFLOW_DIR/.ci/common" ]; then
	echo "error: could not find .ci/common in Workflow at $WORKFLOW_DIR"
	exit 1
fi

. "$WORKFLOW_DIR"/.ci/common/project.sh

# annoying
if [ "$DEVEL" = "true" ]; then
	UPDATES=OFF
else
	UPDATES=ON
fi

if [ "$BUILD_ID" = nightly ]; then
	NIGHTLY=ON
fi

# platform handling
. "$WORKFLOW_DIR"/.ci/common/platform.sh

# sdl/arch handling (targets)
. "$WORKFLOW_DIR"/.ci/common/targets.sh

# compiler handling
. "$WORKFLOW_DIR"/.ci/common/compiler.sh

# Flags all targets use
COMMON_FLAGS=(
	# Do not build tests
	-DBUILD_TESTING=OFF

	# build type
	-DCMAKE_BUILD_TYPE="${BUILD_TYPE:-Release}"

	# Qt
	-DYUZU_USE_BUNDLED_QT="${BUNDLE_QT:-OFF}"
	-DYUZU_USE_QT_MULTIMEDIA="${USE_MULTIMEDIA:-OFF}"
	-DYUZU_USE_QT_WEB_ENGINE="${USE_WEBENGINE:-OFF}"
	-DENABLE_QT_TRANSLATION=ON
	-DENABLE_UPDATE_CHECKER="${UPDATES:-ON}"

	# misc
	-DUSE_CCACHE="${CCACHE:-OFF}"
	-DUSE_DISCORD_PRESENCE=ON

	# LTO
	-DENABLE_LTO="${LTO:-ON}"

	# many distros do not package sirit, so let's bundle it anyways
	-DYUZU_USE_BUNDLED_SIRIT="${SIRIT:-ON}"

	# Bundled stuff (only if not building for a pkg)
	-DYUZU_USE_BUNDLED_FFMPEG="${FFMPEG:-ON}"
	-DYUZU_USE_BUNDLED_OPENSSL="${OPENSSL:-ON}"

	# macos only
	-DYUZU_USE_BUNDLED_MOLTENVK=ON

	# We do NOT want to bundle LLVM
	-DYUZU_DISABLE_LLVM=ON

	# Static Linking
	-DYUZU_STATIC_BUILD="${STATIC:-OFF}"

	# Bundled Qt
	-DYUZU_USE_BUNDLED_QT="${QT:-OFF}"

	# packaging stuff
	-DCMAKE_INSTALL_PREFIX=/usr
	-DYUZU_CMD="${STANDALONE:-OFF}"

	# The room functionality is bundled in now.
	# We don't need it standalone
	-DYUZU_ROOM_STANDALONE=OFF

	-DNIGHTLY_BUILD="${NIGHTLY:-OFF}"
)

# cmd line stuff
EXTRA_ARGS=("$@")

if [ "$PLATFORM" = macos ]; then
	EXTRA_ARGS+=(-DMbedTLS_FORCE_BUNDLED=ON)
fi

# aggregate
CMAKE_FLAGS=(
	"${COMMON_FLAGS[@]}"
	"${SDL_FLAGS[@]}"
	"${ARCH_CMAKE[@]}"
	"${COMPILER_FLAGS[@]}"
	"${PLATFORM_FLAGS[@]}"
	"${EXTRA_ARGS[@]}"
)

echo "-- Configure flags: ${CMAKE_FLAGS[*]}"

cmake -S "$ROOTDIR" -B "$BUILDDIR" -G "Ninja" "${CMAKE_FLAGS[@]}"
