#!/bin/sh -e

BASE="git make autoconf libtool automake-wrapper patch jq"
MINGW="SDL2 cmake python-pip qt6-base qt6-tools qt6-translations toolchain boost catch fmt lz4 nlohmann-json zlib zstd enet opus mbedtls vulkan-devel libusb vulkan-memory-allocator unordered_dense clang ccache"

PACKAGES="$BASE"

for pkg in $MINGW; do
    PACKAGES="$PACKAGES mingw-w64-x86_64-$pkg"
done

pacman -Syu --noconfirm --needed $PACKAGES