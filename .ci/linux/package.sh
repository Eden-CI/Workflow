#!/bin/sh -e

# SPDX-FileCopyrightText: 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# This script assumes you're in the source directory

URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

export ICON="$PWD"/dist/dev.eden_emu.eden.svg
export DESKTOP="$PWD"/dist/dev.eden_emu.eden.desktop
export OPTIMIZE_LAUNCH=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1

case "$1" in
    amd64|"")
        echo "Packaging amd64-v3 optimized build of Eden"
        ARCH="amd64"
        ;;
    steamdeck)
        echo "Packaging Steam Deck (Zen 2) optimized build of Eden"
        ARCH="steamdeck"
        ;;
    rog-ally|allyx)
        echo "Packaging ROG Ally X (Zen 4) optimized build of Eden"
        ARCH="rog-ally-x"
        ;;
    legacy)
        echo "Packaging amd64 generic build of Eden"
        ARCH=legacy
        ;;
    aarch64)
        echo "Packaging armv8-a build of Eden"
        ARCH=aarch64
        ;;
    armv9)
        echo "Packaging armv9-a build of Eden"
        ARCH=armv9
        ;;
esac

BUILDDIR=${BUILDDIR:-build}

EDEN_TAG=$(cat GIT-TAG)
echo "Making \"$EDEN_TAG\" build"
# git checkout "$EDEN_TAG"
VERSION="$(echo "$EDEN_TAG")"

export OUTNAME="Eden-$VERSION-$ARCH.AppImage"
export UPINFO="gh-releases-zsync|eden-emulator|Releases|latest|*-$ARCH.AppImage.zsync"

if [ "$DEVEL" = 'true' ]; then
	sed -i 's|Name=Eden|Name=Eden Nightly|' "$DESKTOP"
 	UPINFO="$(echo "$UPINFO" | sed 's|Releases|nightly|')"
fi

# deploy
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun "$BUILDDIR"/bin/eden

# Wayland is mankind's worst invention, perhaps only behind war
echo 'QT_QPA_PLATFORM=xcb' >> AppDir/.env

# MAKE APPIMAGE WITH URUNTIME
echo "Generating AppImage..."

wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

if [ "$DEVEL" = 'true' ]; then
    rm -f ./*.AppImage.zsync
fi

echo "All Done!"
