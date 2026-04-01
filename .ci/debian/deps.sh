#!/bin/sh -e

# TODO(crueter): surely there's *some* way to dedupe this... right???

# all versions...?
set -- autoconf glslang-tools cmake git gcc g++ ninja-build \
    qt6-tools-dev libtool nasm pkg-config nlohmann-json3-dev spirv-headers \
    libglu1-mesa-dev libhidapi-dev libpulse-dev libudev-dev \
    libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 \
    libxcb-xinerama0 libxcb-xkb1 libxext-dev libxkbcommon-x11-0 mesa-common-dev \
    qt6-base-private-dev libenet-dev libsimpleini-dev libcpp-jwt-dev libfmt-dev \
    liblz4-dev libzstd-dev libssl-dev libavfilter-dev libavcodec-dev \
    libswscale-dev zlib1g-dev libva-dev libvdpau-dev libcpp-httplib-dev \
    libcubeb-dev libvulkan-dev spirv-tools libusb-1.0-0-dev libsdl2-dev \
    libqt6core5compat6 libquazip1-qt6-dev libopus-dev qt6-charts-dev


# Awesome
if [ "$DEBIAN_VERSION" -eq 12 ]; then
    set -- "$@" libboost-context1.81-dev libboost-fiber1.81-dev
fi

# trixie
if [ "$DEBIAN_VERSION" -ge 13 ]; then
    set -- "$@" libfrozen-dev libvulkan-memory-allocator-dev \
        libasound2t64 libboost-context-dev libboost-fiber-dev
fi

apt install "$@"