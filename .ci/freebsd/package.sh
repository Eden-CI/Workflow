#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# This script assumes you're in the source directory

ROOTDIR="$PWD"
BUILDDIR="${BUILDDIR:-$ROOTDIR/build}"
ARTIFACTS_DIR="$ROOTDIR/artifacts"

# shellcheck disable=SC1091
WORKFLOW_DIR=$(CDPATH='' cd -P -- "$(dirname -- "$0")/../.." && pwd)
. "$WORKFLOW_DIR/.ci/common/project.sh"

VERSION=$(cat "$ROOTDIR/GIT-TAG" 2>/dev/null || cat "$WORKFLOW_DIR/WORKFLOW-TAG")
PKG_NAME="${PROJECT_PRETTYNAME}-${VERSION}-${ARCH}"
PKG_DIR="$ROOTDIR/install/usr"

echo "Making '$VERSION' build"

mkdir -p "$PKG_DIR/lib/qt6"

# Copy all linked libs
ldd "$PKG_DIR/bin/${PROJECT_REPO}" | awk '/=>/ {print $3}' | while read -r lib; do
	case "$lib" in
		/lib*|/usr/lib*) ;;  # Skip system libs
		*)
			if echo "$lib" | grep -q '^/usr/local/lib/qt6/'; then
				cp "$lib" "$PKG_DIR/lib/qt6/"
			else
				cp "$lib" "$PKG_DIR/lib/"
			fi
			;;
	esac
done

# Copy Qt6 plugins
QT6_PLUGINS="/usr/local/lib/qt6/plugins"
QT6_PLUGIN_SUBDIRS="
imageformats
iconengines
platforms
platformthemes
platforminputcontexts
styles
xcbglintegrations
wayland-decoration-client
wayland-graphics-integration-client
wayland-graphics-integration
wayland-shell-integration
"

for sub in $QT6_PLUGIN_SUBDIRS; do
	if [ -d "$QT6_PLUGINS/$sub" ]; then
		mkdir -p "$PKG_DIR/lib/qt6/plugins/$sub"
		cp -r "$QT6_PLUGINS/$sub"/* "$PKG_DIR/lib/qt6/plugins/$sub/"
	fi
done

# Copy Qt6 translations
mkdir -p "$PKG_DIR/share/translations"
cp "$BUILDDIR/src/yuzu"/*.qm "$PKG_DIR/share/translations/"

# Strip binaries
strip "$PKG_DIR/bin/${PROJECT_REPO}"
find "$PKG_DIR/lib" -type f -name '*.so*' -exec strip {} \;

# Create a launcher for the pack
cp "$WORKFLOW_DIR/.ci/freebsd/launch.sh" "$PKG_DIR"
chmod +x "$PKG_DIR/launch.sh"

# Pack for upload
mkdir -p "$ARTIFACTS_DIR"
cd "$PKG_DIR"
tar --zstd -cvf "$ARTIFACTS_DIR/$PKG_NAME.tar.zst" .

echo "FreeBSD package created at: $ARTIFACTS_DIR/$PKG_NAME.tar.zst"
