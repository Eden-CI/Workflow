#!/bin/sh

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

brew update
brew install --formula --quiet \
  autoconf \
  automake \
  boost \
  Catch2 \
  cmake \
  create-dmg \
  cubeb \
  enet \
  fmt \
  glslang \
  hidapi \
  libtool \
  libusb \
  lld \
  llvm@22 \
  lz4 \
  molten-vk \
  ninja \
  nlohmann-json \
  openssl \
  opus \
  pkg-config \
  speexdsp \
  spirv-headers \
  spirv-tools \
  vulkan-headers \
  vulkan-loader \
  vulkan-utility-libraries \
  zlib \
  zstd

brew uninstall llvm@23