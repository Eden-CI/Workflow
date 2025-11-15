#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# This script assumes you're in the source directory

# shellcheck disable=SC1091

ROOTDIR="$PWD"
BUILDDIR="${BUILDDIR:-build}"

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

export ICON="$ROOTDIR/dist/dev.eden_emu.eden.svg"
export DESKTOP="$ROOTDIR/dist/dev.eden_emu.eden.desktop"
export OPTIMIZE_LAUNCH=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1

if [ -d "${BUILDDIR}/bin/Release" ]; then
    strip -s "${BUILDDIR}/bin/Release/"*
else
    strip -s "${BUILDDIR}/bin/"*
fi

VERSION=$(cat "$ROOTDIR/GIT-TAG" 2>/dev/null || echo 'v0.0.4-Workflow')
echo "Making \"$VERSION\" build"

export OUTNAME="Eden-$VERSION-$FULL_ARCH.AppImage"
UPINFO="gh-releases-zsync|eden-emulator|Releases|latest|*-$FULL_ARCH.AppImage.zsync"

if [ "$DEVEL" = 'true' ]; then
    case "$(uname)" in
        FreeBSD|Darwin) sed -i '' 's|Name=Eden|Name=Eden Nightly|' "$DESKTOP" ;;
        *) sed -i 's|Name=Eden|Name=Eden Nightly|' "$DESKTOP" ;;
    esac
    UPINFO="$(echo "$UPINFO" | sed 's|Releases|nightly|')"
fi

export UPINFO

# deploy
download "$SHARUN" "$ROOTDIR/quick-sharun"
chmod +x "$ROOTDIR/quick-sharun"
env LC_ALL=C "$ROOTDIR/quick-sharun" "$BUILDDIR/bin/eden"

# Wayland is mankind's worst invention, perhaps only behind war
mkdir -p "$ROOTDIR/AppDir"
echo 'QT_QPA_PLATFORM=xcb' >> "$ROOTDIR/AppDir/.env"

# MAKE APPIMAGE WITH URUNTIME
echo "Generating AppImage..."
download "$URUNTIME" "$ROOTDIR/uruntime2appimage"
chmod +x "$ROOTDIR/uruntime2appimage"
"$ROOTDIR/uruntime2appimage"

if [ "$DEVEL" = 'true' ]; then
    rm -f "$ROOTDIR"/*.AppImage.zsync
fi

echo "Linux package created!"
