#!/bin/sh

set -eux

EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
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
		qt6-wayland \
		spirv-headers \
		spirv-tools \
		strace \
		unzip \
		ffnvcodec-headers \
		vulkan-headers \
		vulkan-mesa-device-select \
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
		pacman -Syu --noconfirm haskell-gnutls svt-av1
fi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-mesa qt6-base-mini libxml2-mini llvm-libs-mini opus-nano intel-media-driver gdk-pixbuf2-mini

echo "All done!"
echo "---------------------------------------------------------------"
