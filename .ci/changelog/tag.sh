#!/bin/sh -ex

BASE_DOWNLOAD_URL="https://github.com/eden-emulator/Releases/releases/download"
TAG="$FORGEJO_REF"

linux() {
  ARCH="$1"
  PRETTY_ARCH="$2"
  DESCRIPTION="$3"

  echo -n "| "
  echo -n "[$PRETTY_ARCH](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Linux-${TAG}-${ARCH}.AppImage) "
  echo -n "([zsync](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Linux-${TAG}-${ARCH}.AppImage.zsync)) | "
  echo -n "$DESCRIPTION |"
  echo
}

win() {
  ARCH="$1"
  PRETTY_ARCH="$2"
  DESCRIPTION="$3"

  echo -n "| "
  echo -n "[$PRETTY_ARCH](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Windows-${TAG}-${ARCH}.zip) | "
  echo -n "$DESCRIPTION |"
  echo
}

android() {
  TYPE="$1"
  SUFFIX="$2"
  DESCRIPTION="$3"

  echo -n "| "
  echo -n "[Android $TYPE](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Android-${TAG}${SUFFIX}.apk) |"
  echo -n "$DESCRIPTION |"
  echo
}

src() {
  EXT="$1"
  DESCRIPTION="$2"

  echo -n "| "
  echo -n "[$EXT](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Source-${TAG}.${EXT}) | "
  echo -n "$DESCRIPTION |"
  echo
}

echo "## Changelog"
echo
echo "## Packages"
echo
echo "Desktop builds will automatically put data in \`~/.local/share/eden\` on Linux, or "
echo "\`%APPDATA%/eden\` on Windows. You may optionally create a \`user\` directory in the "
echo "same directory as the executable/AppImage to store data there instead."
echo
echo "### Linux"
echo
echo "Linux packages are distributed via AppImage. Each build is optimized for a specific architecture."
echo "See the *Description* column for more info. Note that legacy builds will always work on newer systems."
echo "zsync files are provided for use with certain AppImage updaters."
echo
echo ">[!WARNING]"
echo ">By default, the AppImages enforce the \`xcb\` platform for Qt. Wayland causes a significant "
echo ">amount of issues that simply can't be solved on our end. You may change it to Wayland if you "
echo ">wish, but expect things to break. You will only receive limited support if using Wayland."
echo
echo "| Build | Description |"
echo "| ----- | ----------- |"
linux legacy "amd64 (legacy)" "For CPUs older than 2013 or so"
linux amd64 "amd64" "For any modern AMD or Intel CPU"
linux steamdeck "Steam Deck" "For Steam Deck and other >= Zen 2 AMD CPUs"
linux rog-ally "ROG Ally X" "For ROG Ally X and other >= Zen 4 AMD CPUs"
echo "| aarch64 (WIP) | For any 64-bit ARM CPU. Currently a work-in-progress."
echo "| armv9-a (WIP) | For any 64-bit ARM CPU made after late 2021 or so. Currently a work-in-progress."
# linux aarch64 "armv8-a (WIP)" "For ARM CPUs made in mid-2021 or earlier"
# linux armv9 "armv9-a (WIP)" "For ARM CPUs made in late 2021 or later"
echo
echo "### Windows"
echo
echo "Windows packages are in-place zip files."
echo
echo "| Build | Description |"
echo "| ----- | ----------- |"
win amd64-msvc amd64 "For any Windows machine running an AMD or Intel CPU"
win arm64-msvc aarch64 "For any Windows machine running a Qualcomm or other ARM-based SoC"
echo
echo "We are additionally providing experimental packages built with clang, rather than MSVC. These builds should be identical, if not faster,"
echo "but how it affects the overall experience is currently unknown."
echo
echo "| Build | Description |"
echo "| ----- | ----------- |"
win amd64-clang "amd64 (clang)" "For any Windows machine running an AMD or Intel CPU (clang-cl build)"
win arm64-clang "aarch64 (clang)" "For any Windows machine running a Qualcomm or other ARM-based SoC (clang-cl build)"
echo
echo "### Android"
echo
echo "| Build  | Description |"
echo "|--------|-------------|"
android Standard "" "Single APK for all supported Android devices (most users should use this)"
android Optimized "-Optimized" "For any Android device that has Frame Generation or any other per-device feature"
android Legacy "-Legacy" "For A6xx. Fixes any games that work on newer devices but don't on Adreno 6xx"
echo
echo "### Source"
echo
echo "Contains all source code, submodules, and CPM cache at the time of release."
echo
echo "| File | Description |"
echo "| ---- | ----------- |"
src "tar.zst" "Source as a zstd-compressed tarball (Windows requires 7zip)"
echo
echo "### Other Platforms"
echo
echo "Other platforms, including FreeBSD, Solaris (OpenIndiana), and macOS are "
echo "able to be built from source, but are not available for download at this time. "
echo "Stay tuned!"
