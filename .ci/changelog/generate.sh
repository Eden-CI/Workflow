#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

case "$1" in
master)
	TAG="v${TIMESTAMP}.${FORGEJO_REF}"
	REF="${FORGEJO_REF}"
	BASE_DOWNLOAD_URL="https://$RELEASE_MASTER_HOST/$RELEASE_MASTER_REPO/releases/download"
	;;
pull_request)
	TAG="${FORGEJO_PR_NUMBER}-${FORGEJO_REF}"
	REF="${FORGEJO_PR_NUMBER}-${FORGEJO_REF}"
	BASE_DOWNLOAD_URL="https://$RELEASE_PR_HOST/$RELEASE_PR_REPO/releases/download"
	;;
tag)
	TAG="${FORGEJO_REF}"
	REF="${FORGEJO_REF}"
	BASE_DOWNLOAD_URL="https://$RELEASE_TAG_HOST/$RELEASE_TAG_REPO/releases/download"
	;;
push | test)
	TAG="v${TIMESTAMP}.${FORGEJO_REF}"
	REF="${FORGEJO_REF}"
	BASE_DOWNLOAD_URL="https://$RELEASE_MASTER_HOST/$RELEASE_MASTER_REPO/releases/download"
	;;
*)
	echo "Type: $1"
	echo "Supported types: master | pull_request | tag | push | test"
	exit 1
	;;
esac

COMPARE_RELEASE_URL="https://$RELEASE_MASTER_HOST/$RELEASE_MASTER_REPO/releases"

tagged() {
	[ "$DEVEL" != "true" ]
}

win() {
	ARCH="$1"
	PRETTY_ARCH="$2"
	DESCRIPTION="$3"

	echo -n "| "
	echo -n "[$PRETTY_ARCH](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Windows-${REF}-${ARCH}.zip) | "
	echo -n "$DESCRIPTION |"
	echo
}

msys() {
	ARCH="$1"
	PRETTY_ARCH="$2"
	DESCRIPTION="$3"

	echo -n "| "
	echo -n "[$PRETTY_ARCH](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Windows-MinGW-${REF}-${ARCH}.zip) | "
	echo -n "$DESCRIPTION |"
	echo
}

android() {
	TYPE="$1"
	FLAVOR="$2"
	DESCRIPTION="$3"

	echo -n "| "
	echo -n "[Android $TYPE](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Android-${REF}-${FLAVOR}.apk) |"
	echo -n "$DESCRIPTION |"
	echo
}

src() {
	EXT="$1"
	DESCRIPTION="$2"

	echo -n "| "
	echo -n "[$EXT](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Source-${REF}.${EXT}) | "
	echo -n "$DESCRIPTION |"
	echo
}

case "$1" in
master)
	echo "Eden's 'master' branch build, commit for reference:"
	echo "- [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF)"
	echo
	echo "Full changelog: [\`$FORGEJO_BEFORE...$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/compare/$FORGEJO_BEFORE...$FORGEJO_REF)"
	;;
pull_request)
	echo "Eden's Pull Request Number #[$FORGEJO_PR_NUMBER]($FORGEJO_PR_URL)"
	echo
	echo "Commit for reference:"
	echo "- [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF)"
	echo
	echo "Commit used as the merge base for this Pull Request:"
	echo "- [\`$FORGEJO_PR_MERGE_BASE\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_PR_MERGE_BASE)"
	echo
	echo "Corresponding 'master' build for reference:"
	echo "- [\`$FORGEJO_REF\`]($COMPARE_RELEASE_URL?q=$FORGEJO_PR_MERGE_BASE&expanded=true)"
	echo
	echo "## Changelog"
	.ci/common/field.py field="body" default_msg="No changelog provided" pull_request_number="$FORGEJO_PR_NUMBER"
	;;
tag)
	echo "## Changelog"
	;;
push | test)
	echo "Eden's Continuous Integration Test Build"
	;;
esac
echo

linux_field() {
	ARCH="$1"
	PRETTY_ARCH="$2"
	NOTES="${3}"

	echo -n "| $PRETTY_ARCH | "
	echo -n "[GCC](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Linux-${REF}-${ARCH}-gcc-standard.AppImage) "
	if tagged; then
		echo -n "([zsync](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Linux-${REF}-${ARCH}-gcc-standard.AppImage.zsync)) | "
		echo -n "[PGO](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Linux-${REF}-${ARCH}-clang-pgo.AppImage) "
		echo -n "([zsync](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Linux-${REF}-${ARCH}-clang-pgo.AppImage.zsync))"
	fi

	echo "| $NOTES |"
}

linux_matrix() {
	linux_field amd64 "amd64"
	tagged && linux_field legacy "Legacy amd64" "Pre-Ryzen or Haswell CPUs (expect sadness)"
	linux_field steamdeck "Steam Deck" "Zen 2, with additional patches for SteamOS"
	tagged && linux_field rog-ally "ROG Ally X" "Zen 4"
	[ "$DISABLE_ARM" != "true" ] && linux_field aarch64 "aarch64"
}

deb_field() {
	BUILD="$1"
	NOTES="${2}"
	NAME="${BUILD//-/ }"

	echo -n "| $NAME | "
	for ARCH in amd64 aarch64; do
		echo -n "[$ARCH](${BASE_DOWNLOAD_URL}/${TAG}/Eden-$BUILD-${REF}-${ARCH}.deb) | "
	done

	echo "$NOTES |"
}

deb_matrix() {
    deb_field Ubuntu-24.04 "Not compatible with Ubuntu 25.04 or later"
	deb_field Debian-12 "Drivers may be old"
	deb_field Debian-13
}

win_field() {
	LABEL="$1"
	COMPILER="$2"
	NOTES="$3"

	echo -n "| $LABEL | "
	echo -n "[amd64](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Windows-${REF}-amd64-${COMPILER}.zip) | "
	[ "$MINGW" != "true" ] && echo -n "[arm64](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Windows-${REF}-arm64-${COMPILER}.zip)"

	echo " | $NOTES |"
}

win_matrix() {
	MINGW=false
	win_field MSVC msvc-standard
	tagged && win_field PGO clang-pgo

	MINGW=true
	win_field "MinGW GCC" mingw-gcc-standard "May have additional bugs/glitches"
	tagged && win_field "MinGW PGO" mingw-clang-pgo || true
}

cat << EOF

## Targets

Each build is optimized for a specific architecture and uses a specific compiler.

- **aarch64/arm64**: For devices that use the armv8-a instruction set; e.g. Snapdragon X, all Android devices, and Apple Silicon Macs.
- **amd64**: For devices that use the amd64 (aka x86_64) instruction set; this is exclusively used by Intel and AMD CPUs and is only found on desktops.

**Compilers**

- **MSVC**: The default compiler for Windows. This is the most stable experience, but may lack in performance compared to any of the following alternatives.
- **Clang**: An alternative compiler that provides theoretically higher performance, but may have additional graphical glitches.
- **GCC**: The standard GNU compiler; this is the default for Linux and will provide the most stable experience.
- **PGO**: These are built with Clang, and use PGO:

PGO (profile-guided optimization) uses data from prior compilations to determine the "hotspots" found within the codebase. Using these hotspots,
it can allocate more resources towards these heavily-used areas, and thus generally see improved performance to the tune of ~10-50%,
depending on the specific game, hardware, and platform. Do note that additional instabilities may occur.

### Linux

Linux packages are distributed via AppImage.
EOF

if tagged; then
cat << EOF
[zsync](https://zsync.moria.org.uk/) files are provided for easier updating.

| Build Type | GCC | PGO | Notes |
|------------|-----|-----|-------|
EOF
else
cat << EOF

| Build Type | GCC | Notes |
|------------|-----|-------|
EOF
fi

linux_matrix

cat << EOF

### Debian/Ubuntu

Debian/Ubuntu targets are \`.deb\` files, which can be installed via \`sudo dpkg -i <package>.deb\`.

| Target | amd64 | aarch64 | Notes |
|--------|-------|---------|-------|
EOF

deb_matrix

cat << EOF

### Windows

Windows packages are in-place zip files. Setup files are soon to come.
Note that arm64 builds are extremely experimental and are unlikely to work at all.

| Compiler | amd64 | arm64 | Notes |
|----------|-------|-------|-------|
EOF

win_matrix

cat << EOF

### Android

| Build  | Description |
|--------|-------------|
EOF

android Standard "standard" "Single APK for all supported Android devices (most users should use this)"
if [ "$DEVEL" != true ]; then
	android Optimized "optimized" "For any Android device that has Frame Generation or any other per-device feature"
	android Legacy "legacy" "For Adreno A6xx and other older GPUs"
fi


cat << EOF

### macOS

macOS comes in a tarballed app. These builds are currently experimental, and you should expect major graphical glitches and crashes.
In order to run the app, you *may* need to go to System Settings -> Privacy & Security -> Security -> Allow untrusted app.

| File | Description |
| ---- | ----------- |
| [macOS](${BASE_DOWNLOAD_URL}/${TAG}/Eden-macOS-${REF}.tar.gz) | For Apple Silicon (M1, M2, etc)|

### Source

Contains all source code, submodules, and CPM cache at the time of release.
This can be extracted with \`tar xf Eden-Source-${REF}.tar.zst\`.

| File | Description |
| ---- | ----------- |
| [tar.zst](${BASE_DOWNLOAD_URL}/${TAG}/Eden-Source-${REF}.tar.zst) | Source as a zstd-compressed tarball (Windows: use Git Bash or MSYS2) |

EOF