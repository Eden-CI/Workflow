#!/bin/sh -e

# SPDX-FileCopyrightText: 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# This script assumes you're in the source directory

# shellcheck disable=SC1091

download() {
    url="$1"; out="$2"
    if command -v wget >/dev/null 2>&1; then
        wget --retry-connrefused --tries=30 "$url" -O "$out"
    elif command -v curl >/dev/null 2>&1; then
        curl -L --retry 30 -o "$out" "$url"
    elif command -v fetch >/dev/null 2>&1; then
        fetch -o "$out" "$url"
    else
        echo "Error: no downloader found." >&2
        exit 1
    fi
}

URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

export ICON="$PWD"/dist/dev.eden_emu.eden.svg
export DESKTOP="$PWD"/dist/dev.eden_emu.eden.desktop
export OPTIMIZE_LAUNCH=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1

. .ci/common/targets.sh

BUILDDIR=${BUILDDIR:-build}

if [ -d "${BUILDDIR}/bin/Release" ]; then
    strip -s "${BUILDDIR}/bin/Release/"*
else
    strip -s "${BUILDDIR}/bin/"*
fi

VERSION=$(cat GIT-TAG)
echo "Making \"$VERSION\" build"

export OUTNAME="Eden-$VERSION-$ARCH.AppImage"
UPINFO="gh-releases-zsync|eden-emulator|Releases|latest|*-$ARCH.AppImage.zsync"

if [ "$DEVEL" = 'true' ]; then
    case "$(uname)" in
        FreeBSD|Darwin) sed -i '' 's|Name=Eden|Name=Eden Nightly|' "$DESKTOP" ;;
        *) sed -i 's|Name=Eden|Name=Eden Nightly|' "$DESKTOP" ;;
    esac
    UPINFO="$(echo "$UPINFO" | sed 's|Releases|nightly|')"
fi

export UPINFO

# deploy
download "$SHARUN" ./quick-sharun
chmod +x ./quick-sharun
env LC_ALL=C ./quick-sharun "$BUILDDIR/bin/eden"

# Wayland is mankind's worst invention, perhaps only behind war
mkdir -p AppDir
echo 'QT_QPA_PLATFORM=xcb' >> AppDir/.env

# MAKE APPIMAGE WITH URUNTIME
echo "Generating AppImage..."
download "$URUNTIME" ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

if [ "$DEVEL" = 'true' ]; then
    rm -f ./*.AppImage.zsync
fi

echo "All Done!"
