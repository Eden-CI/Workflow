#!/bin/sh

set -eux

sed -i 's/DownloadUser/#DownloadUser/g' /etc/pacman.conf

if [ "$(uname -m)" = 'x86_64' ]; then
		PKG_TYPE='x86_64.pkg.tar.zst'
else
		PKG_TYPE='aarch64.pkg.tar.xz'
fi

LLVM_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/llvm-libs-nano-$PKG_TYPE"
QT6_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/qt6-base-iculess-$PKG_TYPE"
LIBXML_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/libxml2-iculess-$PKG_TYPE"
OPUS_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/opus-nano-$PKG_TYPE"
INTEL_MEDIA_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/intel-media-mini-$PKG_TYPE" 

MESA_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/mesa-mini-$PKG_TYPE"
RADEON_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/vulkan-radeon-mini-$PKG_TYPE"
NOUVEAU_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/vulkan-nouveau-mini-$PKG_TYPE"
INTEL_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/vulkan-intel-mini-$PKG_TYPE"

FREEDRENO_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/vulkan-freedreno-mini-$PKG_TYPE"
PANFROST_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/vulkan-panfrost-mini-$PKG_TYPE"
BROADCOM_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/vulkan-broadcom-mini-$PKG_TYPE"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
		base-devel \
		catch2 \
		cmake \
		curl \
		gamemode \
		git \
		glslang \
		inetutils \
		jq \
		libva \
		libvpx \
		nasm \
		ninja \
		patchelf \
		pulseaudio \
		pulseaudio-alsa \
		python-requests \
		qt6ct \
		qt6-tools \
		qt6-wayland \
		spirv-headers \
		strace \
		unzip \
		ffnvcodec-headers \
		vulkan-headers \
		vulkan-mesa-layers \
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
		wget -q --retry-connrefused --tries=30 "$INTEL_MEDIA_URL" -O ./intel-media.pkg.tar.zst
		wget -q --retry-connrefused --tries=30 "$RADEON_URL" -O ./vulkan-radeon.pkg.tar.zst
		wget -q --retry-connrefused --tries=30 "$INTEL_URL" -O ./vulkan-intel.pkg.tar.zst
		wget -q --retry-connrefused --tries=30 "$NOUVEAU_URL" -O ./vulkan-nouveau.pkg.tar.zst
else
		wget -q --retry-connrefused --tries=30 "$FREEDRENO_URL" -O ./vulkan-freedreno.pkg.tar.zst
		wget -q --retry-connrefused --tries=30 "$PANFROST_URL" -O ./vulkan-panfrost.pkg.tar.zst
		wget -q --retry-connrefused --tries=30 "$BROADCOM_URL" -O ./vulkan-broadcom.pkg.tar.zst
fi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$MESA_URL"   -O  ./mesa.pkg.tar.zst
wget --retry-connrefused --tries=30 "$LLVM_URL"   -O  ./llvm-libs.pkg.tar.zst
wget --retry-connrefused --tries=30 "$QT6_URL"    -O  ./qt6-base-iculess.pkg.tar.zst
wget --retry-connrefused --tries=30 "$LIBXML_URL" -O  ./libxml2-iculess.pkg.tar.zst
wget --retry-connrefused --tries=30 "$OPUS_URL"   -O  ./opus-nano.pkg.tar.zst

pacman -U --noconfirm ./*.pkg.tar.zst
rm -f ./*.pkg.tar.zst

echo "All done!"
echo "---------------------------------------------------------------"
