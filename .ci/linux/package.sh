#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# This script assumes you're in the source directory

# shellcheck disable=SC1091

ROOTDIR="$PWD"
BUILDDIR="${BUILDDIR:-$ROOTDIR/build}"
WORKFLOW_DIR=$(CDPATH='' cd -P -- "$(dirname -- "$0")/../.." && pwd)
. "$WORKFLOW_DIR/.ci/common/project.sh"
ARTIFACTS_DIR="$ROOTDIR/artifacts"

downloadx() {
    url="$1"
    out="$2"
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
    chmod +x "$out"
}

URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

if [ -d "${BUILDDIR}/bin/Release" ]; then
    strip -s "${BUILDDIR}/bin/Release/"*
else
    strip -s "${BUILDDIR}/bin/"*
fi

# variables to be used on quick-sharun and uruntime2appimage
export ICON="$ROOTDIR/dist/dev.eden_emu.eden.svg"
export DESKTOP="$ROOTDIR/dist/dev.eden_emu.eden.desktop"
export OPTIMIZE_LAUNCH=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1
export APPDIR="$ROOTDIR/AppDir"
export APPENV="$ROOTDIR/AppDir/.env"
export OUTPATH="$ARTIFACTS_DIR"
export OUTNAME="${PROJECT_PRETTYNAME}-Linux-${ARTIFACT_REF}-${FULL_ARCH}.AppImage"
UPINFO="gh-releases-zsync|eden-emulator|Releases|latest|*-${FULL_ARCH}.AppImage.zsync"

if [ "$DEVEL" = 'true' ]; then
    case "$(uname)" in
        FreeBSD|Darwin) sed -i '' "s|Name=${PROJECT_PRETTYNAME}|Name=${PROJECT_PRETTYNAME} Nightly|" "$DESKTOP" ;;
        *) sed -i "s|Name=${PROJECT_PRETTYNAME}|Name=${PROJECT_PRETTYNAME} Nightly|" "$DESKTOP" ;;
    esac
    UPINFO="$(echo "$UPINFO" | sed 's|Releases|nightly|')"
fi
export UPINFO

# cleanup
rm -rf "$APPDIR"

# deploy
downloadx "$SHARUN" "$WORKFLOW_DIR/quick-sharun"
env LC_ALL=C "$WORKFLOW_DIR/quick-sharun" \
	"$BUILDDIR/bin/${PROJECT_REPO}" \
	"$BUILDDIR/bin/${PROJECT_REPO}-cli"

# Wayland is mankind's worst invention, perhaps only behind war
mkdir -p "$APPDIR" "$OUTPATH"
echo 'QT_QPA_PLATFORM=xcb' >> "$APPENV"

# MAKE APPIMAGE WITH URUNTIME
echo "Generating AppImage..."
downloadx "$URUNTIME" "$WORKFLOW_DIR/uruntime2appimage"
"$WORKFLOW_DIR/uruntime2appimage"

if [ "$DEVEL" = 'true' ]; then
    rm -f "$OUTPATH/$OUTNAME.zsync"
fi

echo "Linux package created: $OUTPATH/$OUTNAME"
