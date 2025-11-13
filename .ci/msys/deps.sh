#!/bin/sh

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

pacman -Syu --noconfirm
pacman -Syu --noconfirm

pacman -S --noconfirm git make autoconf libtool automake-wrapper patch jq pactoys ninja

pacboy -S --noconfirm \
  qt6-static:p qt6-tools:p qt6-translations:p qt6-svg:p \
  7zip:p sccache:p cmake:p toolchain:p clang:p python-pip:p lld:p \
  openssl:p boost:p fmt:p lz4:p nlohmann-json:p zlib:p zstd:p \
  vulkan-memory-allocator:p vulkan-devel:p glslang:p \
  enet:p opus:p mbedtls:p libusb:p unordered_dense:p \
  jbigkit:p xz:p libdeflate:p bzip2:p lerc:p graphite2:p crt-git:p \
  libwebp:p libtiff:p brotli:p