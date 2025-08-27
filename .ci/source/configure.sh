#!/bin/sh

# Configures CMake in different "presets" to get every possible build type,
# thus caching every potential CPM call.
cd eden

if [ -f "tools/cpm-fetch-all.sh" ]
then
  tools/cpm-fetch-all.sh
else
  cmake -S . -B build \
    -DUSE_DISCORD_PRESENCE=ON \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DYUZU_USE_EXTERNAL_SDL2=ON \
    -DYUZU_USE_BUNDLED_FFMPEG=ON \
    -DBUILD_TESTING=ON \
    -DDYNARMIC_TESTS=ON \
    -DYUZU_TESTS=ON \
    -DYUZU_USE_QT_MULTIMEDIA=OFF \
    -DYUZU_USE_QT_WEB_ENGINE=OFF \
    -DFORCE_DOWNLOAD_WIN_BUNDLES=ON \
    -DYUZU_USE_BUNDLED_OPENSSL=ON \
    -DFORCE_DOWNLOAD_OPENSSL=ON \
    -DYUZU_USE_BUNDLED_SDL2=ON \
    -DFORCE_DOWNLOAD_SDL2=ON \
    -DYUZU_USE_CPM=ON \
    -DYUZU_USE_EXTERNAL_VULKAN_HEADERS=ON \
    -DYUZU_USE_EXTERNAL_VULKAN_UTILITY_LIBRARIES=ON \
    -DYUZU_USE_EXTERNAL_VULKAN_SPIRV_TOOLS=ON \
    -DCPMUTIL_DEFAULT_SYSTEM=OFF \
    "${EXTRA_CMAKE_FLAGS[@]}"
fi