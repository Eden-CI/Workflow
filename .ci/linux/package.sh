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
VERSION="$EDEN_TAG"
OUTNAME="Eden-$VERSION-$ARCH.AppImage"
UPINFO="gh-releases-zsync|eden-emulator|Releases|latest|*-$ARCH.AppImage.zsync"

if [ "$DEVEL" = 'true' ]; then
	case "$(uname)" in
		FreeBSD|Darwin) sed -i '' 's|Name=Eden|Name=Eden Nightly|' "$DESKTOP" ;;
		*) sed -i 's|Name=Eden|Name=Eden Nightly|' "$DESKTOP" ;;
	esac
	UPINFO="$(echo "$UPINFO" | sed 's|Releases|nightly|')"
fi

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

download "$SHARUN" ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun "$BUILDDIR/bin/eden"

# Wayland is mankind's worst invention, perhaps only behind war
mkdir -p AppDir
echo 'QT_QPA_PLATFORM=xcb' >> AppDir/.env

echo "Generating AppImage..."
download "$URUNTIME" ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

if [ "$DEVEL" = 'true' ]; then
	rm -f ./*.AppImage.zsync 2>/dev/null || true
fi

echo "All Done!"
