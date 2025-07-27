#!/bin/sh

export LIBVULKAN_PATH="/opt/homebrew/lib/libvulkan.1.dylib"

if [ -z "$BUILD_TYPE" ]; then
    export BUILD_TYPE="Release"
fi

if [ "$DEVEL" != "true" ]; then
    export EXTRA_CMAKE_FLAGS=("${EXTRA_CMAKE_FLAGS[@]}" -DENABLE_QT_UPDATE_CHECKER=ON)
fi

mkdir -p build && cd build
cmake .. -GNinja \
    -DYUZU_TESTS=OFF \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DUSE_DISCORD_PRESENCE=ON \
    -DYUZU_CMD=OFF \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_CXX_FLAGS="-w" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DYUZU_USE_PRECOMPILED_HEADERS=OFF \
    "${EXTRA_CMAKE_FLAGS[@]}"

ninja