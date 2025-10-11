#!/bin/bash -e

# SPDX-FileCopyrightText: 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

EXTRA_CMAKE_FLAGS=()
case "$1" in
amd64)
    echo "Making amd64-v3 optimized build of Eden"
    ARCH_FLAGS="-march=x86-64-v3 -mtune=generic"
    EXTRA_CMAKE_FLAGS+=(-DYUZU_BUILD_PRESET=v3)
    ;;
aarch64)
    echo "Making armv8-a build of Eden"
    ARCH_FLAGS="-march=armv8-a -mtune=generic"
    EXTRA_CMAKE_FLAGS+=(-DYUZU_BUILD_PRESET=generic)
    ;;
native)
    echo "Making native build of Eden"
    ARCH_FLAGS="-march=native -mtune=native"
    EXTRA_CMAKE_FLAGS+=(-DYUZU_BUILD_PRESET=native)
    ;;
*)
    echo "Invalid target $1 specified, must be one of: native, amd64, aarch64"
    exit 1
    ;;
esac

EXTRA_CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=/usr)

if [ "$COMPILER" = "clang" ]; then
    EXTRA_CMAKE_FLAGS+=(-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++)
fi
echo "Extra CMake flags: ${EXTRA_CMAKE_FLAGS[*]}"

shift
EXTRA_ARGS=("$@")
echo "Extra args: ${EXTRA_ARGS[*]}"

BUILDDIR="${BUILDDIR:-build}"
NUM_JOBS=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)

ARCH_FLAGS="${ARCH_FLAGS} -O3 -pipe -w"

PLATFORM_CMAKE_FLAGS=(
    -DYUZU_USE_CPM=ON
    -DENABLE_WEB_SERVICE=OFF
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
    -DENABLE_QT_UPDATE_CHECKER=OFF \
    -DUSE_CCACHE="${CCACHE:-false}" \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DYUZU_CMD=OFF \
    -DYUZU_ENABLE_LTO="${LTO:-ON}" \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DYUZU_TESTS=OFF \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DYUZU_USE_QT_MULTIMEDIA="${USE_MULTIMEDIA:-false}" \
    -DYUZU_USE_QT_WEB_ENGINE="${USE_WEBENGINE:-false}" \
)
echo "Common flags: ${COMMON_CMAKE_FLAGS[*]}"

cmake -S . -B "${BUILDDIR}" -G Ninja \
    "${COMMON_CMAKE_FLAGS[@]}" \
    "${PLATFORM_CMAKE_FLAGS[@]}" \
    "${EXTRA_CMAKE_FLAGS[@]}" \
    "${EXTRA_ARGS[@]}"

cmake --build "${BUILDDIR}" --parallel "${NUM_JOBS}"

if [ -d "${BUILDDIR}/bin/Release" ]; then
    strip -s "${BUILDDIR}/bin/Release/"*
else
    strip -s "${BUILDDIR}/bin/"*
fi
