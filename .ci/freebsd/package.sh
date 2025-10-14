#!/bin/sh -e

# SPDX-FileCopyrightText: 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# This script assumes you're in the source directory

EDEN_TAG=$(cat GIT-TAG)
VERSION="$(echo "$EDEN_TAG")"
PKG_NAME="Eden-${VERSION}-${ARCH}"
PKG_DIR="install/usr"
BUILDDIR="${BUILDDIR:-build}"

echo "Making \"$EDEN_TAG\" build"

mkdir -p "${PKG_DIR}/lib/qt6"

# Copy all linked libs
ldd "${PKG_DIR}/bin/eden" | awk '/=>/ {print $3}' | while read -r lib; do
  case "$lib" in
    /lib*|/usr/lib*) ;;  # Skip system libs
    *)
      if echo "$lib" | grep -q '^/usr/local/lib/qt6/'; then
        cp -v "$lib" "${PKG_DIR}/lib/qt6/"
      else
        cp -v "$lib" "${PKG_DIR}/lib/"
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
  if [ -d "${QT6_PLUGINS}/${sub}" ]; then
    mkdir -p "${PKG_DIR}/lib/qt6/plugins/${sub}"
    cp -rv "${QT6_PLUGINS}/${sub}"/* "${PKG_DIR}/lib/qt6/plugins/${sub}/"
  fi
done

# Copy Qt6 translations
mkdir -p "${PKG_DIR}/share/translations"
cp -v ${BUILDDIR}/src/yuzu/*.qm "${PKG_DIR}/share/translations/"

# Strip binaries
strip "${PKG_DIR}/bin/eden"
find "${PKG_DIR}/lib" -type f -name '*.so*' -exec strip {} \;

# Create a laucher for the pack
cp .ci/freebsd/launch.sh "${PKG_NAME}"
chmod +x "${PKG_NAME}/launch.sh"

# Pack for upload
XZ_OPT="-9e -T0" tar -cavf "${PKG_NAME}.tar.xz" "${PKG_NAME}"
mkdir -p artifacts
mv -v "${PKG_NAME}.tar.xz" artifacts

echo "All Done!"
