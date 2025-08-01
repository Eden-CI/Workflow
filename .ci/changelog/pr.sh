#!/bin/sh -ex

BASE_DOWNLOAD_URL="https://github.com/Eden-CI/PR/releases/download"
TAG=${FORGEJO_NUMBER}-${FORGEJO_REF}

if [ "$FORGEJO_TOKEN" = "" ]; then
  echo "You must supply a Forgejo API Token via the FORGEJO_TOKEN environment variable."
  exit 1
fi

linux() {
  ARCH="$1"
  PRETTY_ARCH="$2"
  DESCRIPTION="$3"

  echo -n "| "
  echo -n "[$PRETTY_ARCH](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Linux-${FORGEJO_NUMBER}-${FORGEJO_REF}-${ARCH}.AppImage) | "
  echo -n "$DESCRIPTION |"
  echo
}

win() {
  ARCH="$1"
  PRETTY_ARCH="$2"
  DESCRIPTION="$3"

  echo -n "| "
  echo -n "[$PRETTY_ARCH](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Windows-${FORGEJO_NUMBER}-${FORGEJO_REF}-${ARCH}.zip) | "
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

changelog() {
  echo "## Changelog"
  echo
  python3 .ci/changelog/description.py
  echo
}

if [ "$GITHUB_ENV" != "" ]; then
  echo "FORGEJO_TITLE=$FORGEJO_TITLE" >> $GITHUB_ENV
fi

echo "This is pull request number [$FORGEJO_NUMBER]($FORGEJO_PR_URL), ref \`$FORGEJO_REF\` of Eden."
echo
changelog
echo "## Packages"
echo
echo "Desktop builds will automatically put data in \`~/.local/share/eden\` on Linux, or "
echo "\`%APPDATA%/eden\` on Windows. You may optionally create a \`user\` directory in the "
echo "same directory as the executable/AppImage to store data there instead."
echo
echo ">[!WARNING]"
echo ">These builds are provided **as-is**. They are intended for testers and developers ONLY."
echo ">They are made available to the public in the interest of maximizing user freedom, but you"
echo ">**will NOT receive support** while using these builds, *unless* you have useful debug/testing"
echo ">info to share."
echo "> "
echo ">Furthermore, sharing these builds and claiming they are the \"official\" or \"release\""
echo ">builds is **STRICTLY FORBIDDEN** and may result in further action from the Eden development team."
echo
echo "### Linux"
echo
echo "Linux packages are distributed via AppImage. Each build is optimized for a specific architecture."
echo "See the *Description* column for more info. Note that legacy builds will always work on newer systems."
echo
echo "| Build | Description |"
echo "| ----- | ----------- |"
#linux legacy "amd64 (legacy)" "For CPUs older than 2013 or so"
linux amd64 "amd64" "For any modern AMD or Intel CPU"
linux steamdeck "Steam Deck" "For Steam Deck and other >= Zen 2 AMD CPUs"
#linux rog-ally "ROG Ally X" "For ROG Ally X and other >= Zen 4 AMD CPUs"
linux aarch64 "armv8-a" "For ARM CPUs made in mid-2021 or earlier"
#linux armv9 "armv9-a" "For ARM CPUs made in late 2021 or later"
echo
echo "### Windows"
echo
echo "Windows packages are in-place zip files."
echo
echo "| Build | Description |"
echo "| ----- | ----------- |"
win amd64 amd64 "For any Windows machine running an AMD or Intel CPU"
echo "| arm64 (WIP) | For any Windows machine running a Qualcomm or other ARM-based SoC. Currently a work-in-progress."
# win arm64 aarch64 "For any Windows machine running a Qualcomm or other ARM-based SoC"
echo
echo "### Android"
echo
echo "Android comes in a single APK."
echo
echo "[Android APK](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Android-${FORGEJO_NUMBER}-${FORGEJO_REF}.apk)"
echo
echo "### Source"
echo
echo "Contains all source code, submodules, and CPM cache at the time of release."
echo
echo "| File | Description |"
echo "| ---- | ----------- |"
src "zip" "Source as a zip archive (all platforms)"
src "tar.zst" "Source as a zstd-compressed tarball (Windows requires 7zip)"
echo
