#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Use sudo if available, otherwise run directly
if command -v sudo >/dev/null 2>&1 ; then
	SUDO=sudo
fi

if command -v apt >/dev/null 2>&1 ; then
	$SUDO apt update
	$SUDO apt install -y \
		autoconf \
		cmake \
		g++ \
		gcc \
		git \
		glslang-tools \
		libglu1-mesa-dev \
		libhidapi-dev \
		libpulse-dev \
		libtool \
		libudev-dev \
		libxcb-icccm4 \
		libxcb-image0 \
		libxcb-keysyms1 \
		libxcb-render-util0 \
		libxcb-xinerama0 \
		libxcb-xkb1 \
		libxext-dev \
		libxkbcommon-x11-0 \
		mesa-common-dev \
		nasm \
		ninja-build \
		qt6-base-private-dev \
		libmbedtls-dev \
		catch2 \
		libfmt-dev \
		liblz4-dev \
		nlohmann-json3-dev \
		libzstd-dev \
		libssl-dev \
		libavfilter-dev \
		libavcodec-dev \
		libswscale-dev \
		pkg-config \
		zlib1g-dev \
		libva-dev \
		libvdpau-dev \
		qt6-tools-dev \
		libvulkan-dev \
		spirv-tools \
		spirv-headers \
		libusb-1.0-0-dev \
		libboost-dev \
		libboost-fiber-dev \
		libboost-context-dev \
		libsdl2-dev \
		libopus-dev \
		libasound2t64 \
		vulkan-utility-libraries-dev
	if [ "$(uname -m)" = 'x86_64' ]; then
		$SUDO apt install -y libxbyak-dev
	fi
fi
