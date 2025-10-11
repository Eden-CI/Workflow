#!/bin/bash -e

# SPDX-FileCopyrightText: 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

export LIBVULKAN_PATH="/opt/homebrew/lib/libvulkan.1.dylib"

EXTRA_ARGS=("$@")
echo "Extra args: ${EXTRA_ARGS[*]}"

BUILDDIR="${BUILDDIR:-build}"
NUM_JOBS=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)

ARCH_FLAGS="-w"

PLATFORM_CMAKE_FLAGS=(
    -DYUZU_USE_BUNDLED_MOLTENVK=ON
    -DYUZU_USE_BUNDLED_SIRIT=ON
)
echo "Platform flags: ${PLATFORM_CMAKE_FLAGS[*]}"

COMMON_CMAKE_FLAGS=(
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE:-Release}" \
    -DCMAKE_C_FLAGS="${ARCH_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${ARCH_FLAGS}" \
    -DDYNARMIC_ENABLE_LTO="${LTO:-ON}" \
    -DDYNARMIC_TESTS=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DENABLE_QT_UPDATE_CHECKER="${DEVEL:-true}" \
    -DUSE_CCACHE="${CCACHE:-false}" \
    -DUSE_DISCORD_PRESENCE=ON \
    -DYUZU_CMD=OFF \
    -DYUZU_ENABLE_LTO="${LTO:-ON}" \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DYUZU_TESTS=OFF \
    -DYUZU_USE_BUNDLED_QT="${BUNDLE_QT:-false}" \
    -DYUZU_USE_QT_MULTIMEDIA="${USE_MULTIMEDIA:-false}" \
    -DYUZU_USE_QT_WEB_ENGINE="${USE_WEBENGINE:-false}" \
)
echo "Common flags: ${COMMON_CMAKE_FLAGS[*]}"

cmake -S . -B "${BUILDDIR}" -G Ninja \
    "${COMMON_CMAKE_FLAGS[@]}" \
    "${PLATFORM_CMAKE_FLAGS[@]}" \
    "${EXTRA_ARGS[@]}"

cmake --build "${BUILDDIR}" --parallel "${NUM_JOBS}"
