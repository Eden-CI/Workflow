#!/bin/sh

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

pkg install -y \
  devel/cmake \
  devel/sdl20 \
  devel/boost-libs \
  devel/catch2 \
  devel/libfmt \
  devel/nlohmann-json \
  devel/ninja \
  devel/nasm \
  devel/autoconf \
  devel/pkgconf \
  devel/qt6-base \
  devel/qt6-tools \
  devel/xbyak \
  devel/simpleini \
  net/enet \
  multimedia/ffnvcodec-headers \
  multimedia/ffmpeg \
  audio/opus \
  archivers/liblz4 \
  lang/gcc12 \
  security/mbedtls3 \
  www/cpp-httplib \
  x11-servers/xorg-server \
  graphics/glslang \
  graphics/vulkan-headers \
  graphics/vulkan-utility-libraries
