#!/bin/bash -e

# SPDX-FileCopyrightText: 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

if [ -z "${WINDEPLOYQT}" ]; then
    echo "WINDEPLOYQT environment variable required."
    exit 1
fi

EXTRA_CMAKE_FLAGS=()
if [ "$COMPILER" = "clang" ]; then
    EXTRA_CMAKE_FLAGS+=(-DCMAKE_CXX_COMPILER=clang-cl -DCMAKE_C_COMPILER=clang-cl)
    LTO=OFF
fi
echo "Extra CMake flags: ${EXTRA_CMAKE_FLAGS[*]}"

EXTRA_ARGS=("$@")
echo "Extra args: ${EXTRA_ARGS[*]}"

BUILDDIR="${BUILDDIR:-build}"
NUM_JOBS=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)

ARCH_FLAGS=""

PLATFORM_CMAKE_FLAGS=(-DYUZU_USE_BUNDLED_SDL2=ON)
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
    "${EXTRA_CMAKE_FLAGS[@]}" \
    "${EXTRA_ARGS[@]}"

cmake --build "${BUILDDIR}" --parallel "${NUM_JOBS}"

set +e
rm -f "${BUILDDIR}/bin/"*.pdb
set -e

"${WINDEPLOYQT}" --release --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler --dir "${BUILDDIR}/pkg" "${BUILDDIR}/bin/eden.exe"
cp "${BUILDDIR}/bin/"* "${BUILDDIR}/pkg"
