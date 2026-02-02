#!/bin/sh -eux

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

dependencies_arch() {
	EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

	echo "Installing build dependencies..."
	echo "---------------------------------------------------------------"
	pacman -Syu --noconfirm --overwrite "*" \
		base-devel \
		boost-libs \
		boost \
		catch2 \
		clang \
		cmake \
		curl \
		enet \
		ffnvcodec-headers \
		fmt \
		gamemode \
		git \
		glslang \
		inetutils \
		jq \
		libva \
		libvdpau \
		libvpx \
		lld \
		llvm \
		mbedtls \
		mold \
		nasm \
		ninja \
		nlohmann-json \
		patchelf \
		pulseaudio \
		pulseaudio-alsa \
		python-requests \
		qt6ct \
		qt6-tools \
		spirv-headers \
		spirv-tools \
		strace \
		unzip \
		vulkan-headers \
		vulkan-mesa-layers \
		vulkan-utility-libraries \
		wget \
		wireless_tools \
		xcb-util-cursor \
		xcb-util-image \
		xcb-util-renderutil \
		xcb-util-wm \
		xorg-server-xvfb \
		zip \
		zsync

	if [ "$(uname -m)" = 'x86_64' ]; then
		pacman -Syu --noconfirm --overwrite "*" haskell-gnutls svt-av1
	fi

	echo "Installing debloated packages..."
	echo "---------------------------------------------------------------"
	wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
	chmod +x ./get-debloated-pkgs.sh
	./get-debloated-pkgs.sh --add-mesa qt6-base-mini libxml2-mini llvm-libs-mini opus-nano intel-media-driver

	echo "All done!"
	echo "---------------------------------------------------------------"
}

dependencies_debian() {
	# Use sudo if available, otherwise run directly
	SUDO=""
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
}

dependencies_alpine(){
	apk add --no-cache \
		bash cmake g++ gcc git ninja patch boost1.84-dev boost1.84-static \
		mbedtls-dev mbedtls-static
}

if [ -f /etc/os-release ]; then
	. /etc/os-release
fi

case "$ID" in
  debian|ubuntu)
    dependencies_debian
    ;;
  arch)
    dependencies_arch
    ;;
  alpine)
    dependencies_alpine
    ;;
  *)
    echo "[ERROR] Unsupported $ID!"
    ;;
esac
