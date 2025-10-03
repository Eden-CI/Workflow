#!/bin/bash -ex

# SPDX-FileCopyrightText: 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

if [ "$COMPILER" = "clang" ]
then
    EXTRA_CMAKE_FLAGS+=(
        -DCMAKE_CXX_COMPILER=clang-cl
        -DCMAKE_C_COMPILER=clang-cl
    )

    LTO=OFF
fi

[ -z "$WINDEPLOYQT" ] && { echo "WINDEPLOYQT environment variable required."; exit 1; }

echo $EXTRA_CMAKE_FLAGS

BUILDDIR=${BUILDDIR:-build}

cmake -S . -B "$BUILDDIR" -G Ninja \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE:-Release}" \
	-DENABLE_QT_TRANSLATION=ON \
    -DUSE_DISCORD_PRESENCE=ON \
    -DYUZU_USE_BUNDLED_SDL2=ON \
    -DBUILD_TESTING=OFF \
    -DYUZU_TESTS=OFF \
    -DDYNARMIC_TESTS=OFF \
    -DYUZU_CMD=OFF \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DYUZU_USE_QT_MULTIMEDIA=${USE_MULTIMEDIA:-false} \
    -DYUZU_USE_QT_WEB_ENGINE=${USE_WEBENGINE:-false} \
    -DYUZU_ENABLE_LTO=${LTO:-ON} \
    -DDYNARMIC_ENABLE_LTO=${LTO:-ON} \
    -DYUZU_USE_BUNDLED_QT=${BUNDLE_QT:-false} \
    -DUSE_CCACHE=${CCACHE:-false} \
    -DENABLE_QT_UPDATE_CHECKER=${DEVEL:-true} \
    "${EXTRA_CMAKE_FLAGS[@]}" \
    "$@"

ninja -C "$BUILDDIR"

set +e
rm -f "$BUILDDIR/bin/"*.pdb
set -e

$WINDEPLOYQT --release --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler --dir "$BUILDDIR/pkg" "$BUILDDIR/bin/eden.exe"

cp "$BUILDDIR/bin/"* "$BUILDDIR/pkg"
