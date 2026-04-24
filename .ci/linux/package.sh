#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# This script assumes you're in the source directory

# shellcheck disable=SC1091

ROOTDIR="$PWD"
BUILDDIR="${BUILDDIR:-$ROOTDIR/build}"
. "$ROOTDIR/.ci/common/project.sh"
ARTIFACTS_DIR="$ROOTDIR/artifacts"

SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

# variables to be used on quick-sharun and uruntime2appimage
export ICON="$ROOTDIR/dist/dev.eden_emu.eden.svg"
export DESKTOP="$ROOTDIR/dist/dev.eden_emu.eden.desktop"
export OPTIMIZE_LAUNCH=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1

ADD_HOOKS="wayland-is-broken.hook"
if [ "$DEVEL" != "true" ]; then
	ADD_HOOKS="$ADD_HOOKS:self-updater.hook"
fi

export ADD_HOOKS
export OUTPATH="$ARTIFACTS_DIR"
export OUTNAME="${PROJECT_PRETTYNAME}-Linux-${ARTIFACT_REF}-${FULL_ARCH}.AppImage"

_zsync="${PROJECT_PRETTYNAME}-Linux-${FULL_ARCH}.AppImage.zsync"

# Thanks, Microsoft.
# TODO(crueter): Proper fj/b2 handling.
# UPINFO="zsync|https://${RELEASE_HOST}/${RELEASE_REPO}/releases/download/latest/${_zsync}"
UPINFO="zsync|https://${B2_PUBLIC_URL}/latest/${_zsync}"

# shellcheck disable=SC2153
if [ "$BUILD_ID" = 'nightly' ]; then
	sed -i "s|Name=${PROJECT_PRETTYNAME}|Name=${PROJECT_PRETTYNAME} Nightly|" "$DESKTOP"
fi

export UPINFO

# cleanup
rm -rf "$APPDIR"

# deploy
curl -fL --retry 30 "$SHARUN" -o quick-sharun
chmod a+x quick-sharun
./quick-sharun \
	"$BUILDDIR/bin/${PROJECT_REPO}" \
	"$BUILDDIR/bin/${PROJECT_REPO}-cli"

# MAKE APPIMAGE WITH URUNTIME
echo "-- Generating AppImage... --"
./quick-sharun --make-appimage

if [ "$DEVEL" = 'true' ]; then
    rm -f "$OUTPATH/$OUTNAME.zsync"
else
    mv "$OUTPATH/$OUTNAME.zsync" "$OUTPATH/${_zsync}"
fi

echo "Linux package created: $OUTPATH/$OUTNAME"
