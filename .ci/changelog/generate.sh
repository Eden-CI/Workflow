#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091

ROOTDIR="$PWD"
. "$ROOTDIR"/.ci/common/project.sh

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
	falsy "$DEVEL"
}

opts() {
	falsy "$DISABLE_OPTS"
}

case "$1" in
master)
	echo "Master branch build for [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF)"
	echo
	echo "Full changelog: [\`$FORGEJO_BEFORE...$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/compare/$FORGEJO_BEFORE...$FORGEJO_REF)"
	;;
pull_request)
	echo "Pull request build #[$FORGEJO_PR_NUMBER]($FORGEJO_PR_URL)"
	echo
	echo "Commit: [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF)"
	echo
	echo "Merge base: [\`$FORGEJO_PR_MERGE_BASE\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_PR_MERGE_BASE)"
	echo "([Master Build]($COMPARE_RELEASE_URL?q=$FORGEJO_PR_MERGE_BASE&expanded=true))"
	echo
	echo "## Changelog"
	.ci/common/field.py field="body" default_msg="No changelog provided" pull_request_number="$FORGEJO_PR_NUMBER"
	;;
tag)
	echo "## Changelog"
	;;
push | test)
	echo "CI test build"
	;;
esac
echo

android() {
	TYPE="$1"
	FLAVOR="$2"
	DESCRIPTION="$3"

	echo -n "| "
	echo -n "[Android $TYPE](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-Android-${REF}-${FLAVOR}.apk) | "
	echo "$DESCRIPTION |"
}

src() {
	EXT="$1"
	DESCRIPTION="$2"

	echo -n "| "
	echo -n "[$EXT](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-Source-${REF}.${EXT}) | "
	echo -n "$DESCRIPTION |"
	echo
}

linux_field() {
	ARCH="$1"
	PRETTY_ARCH="$2"
	NOTES="${3}"

	echo -n "| $PRETTY_ARCH | "
	echo -n "[GCC](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-Linux-${REF}-${ARCH}-gcc-standard.AppImage) "
	if tagged; then
		echo -n "([zsync](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-Linux-${REF}-${ARCH}-gcc-standard.AppImage.zsync)) | "
		if opts; then
			echo -n "[PGO](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-Linux-${REF}-${ARCH}-clang-pgo.AppImage) "
			echo -n "([zsync](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-Linux-${REF}-${ARCH}-clang-pgo.AppImage.zsync))"
		fi
	fi

	echo "| $NOTES"
}

linux_matrix() {
	linux_field amd64 "amd64"
	if opts; then
		tagged && linux_field legacy "Legacy amd64" "Pre-Ryzen or Haswell CPUs (expect sadness)"
		linux_field steamdeck "Steam Deck" "Zen 2, with additional patches for SteamOS"
		tagged && linux_field rog-ally "ROG Ally X" "Zen 4"
	fi

	falsy "$DISABLE_ARM" && linux_field aarch64 "aarch64"
}

deb_field() {
	BUILD="$1"
	NOTES="${2}"
	NAME="${BUILD//-/ }"

	echo -n "| $NAME | "

	ARCHES=amd64
	tagged && ARCHES="$ARCHES aarch64"
	for ARCH in $ARCHES; do
		echo -n "[$ARCH](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-$BUILD-${REF}-${ARCH}.deb) | "
	done

	echo "$NOTES"
}

deb_matrix() {
    deb_field Ubuntu-24.04 "Not compatible with Ubuntu 25.04 or later"
	deb_field Debian-12 "Drivers may be old"
	deb_field Debian-13
}

room_matrix() {
	for arch in aarch64 x86_64; do
		echo "- [$arch](${BASE_DOWNLOAD_URL}/${TAG}/eden-room-$arch-unknown-linux-musl)"
	done
}

win_field() {
	LABEL="$1"
	COMPILER="$2"
	NOTES="$3"

	echo -n "| $LABEL | "
	echo -n "[amd64](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-Windows-${REF}-amd64-${COMPILER}.zip) | "
	falsy "$DISABLE_MSVC_ARM" && echo -n "[arm64](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-Windows-${REF}-arm64-${COMPILER}.zip)"

	echo " | $NOTES"
}

msys() {
	LABEL="$1"
	AMD="$2"
    ARM="$3"
    TARGET="$4"
	NOTES="$5"

	echo -n "| $LABEL | "
	echo -n "[amd64](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-Windows-${REF}-mingw-amd64-${AMD}-${TARGET}.zip) | "
	echo -n "[arm64](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-Windows-${REF}-mingw-arm64-${ARM}-${TARGET}.zip) | "

	echo "$NOTES"
}

win_matrix() {
	win_field MSVC msvc-standard

	if falsy "$DISABLE_MINGW"; then
		msys "MinGW" gcc clang standard "May have additional bugs/glitches"
		opts && tagged && msys "MinGW PGO" clang clang pgo || true
	fi
}

echo "# Packages"

if truthy "$EXPLAIN_TARGETS"; then
cat << EOF

## Targets

Each build is optimized for a specific architecture and uses a specific compiler.

- **aarch64/arm64**: For devices that use the armv8-a instruction set; e.g. Snapdragon X, all Android devices, and Apple Silicon Macs.
- **amd64**: For devices that use the amd64 (aka x86_64) instruction set; this is exclusively used by Intel and AMD CPUs and is only found on desktops.

**Compilers**

- **MSVC**: The default compiler for Windows. This is the most stable experience, but may lack in performance compared to any of the following alternatives.
- **GCC**: The standard GNU compiler; this is the default for Linux and will provide the most stable experience.
- **PGO**: These are built with Clang, and use PGO. PGO (profile-guided optimization) uses data from prior compilations
	to determine the "hotspots" found within the codebase. Using these hotspots,
	it can allocate more resources towards these heavily-used areas, and thus generally see improved performance to the tune of ~10-50%,
	depending on the specific game, hardware, and platform. Do note that additional instabilities may occur.
EOF
fi

cat << EOF

## Linux

Linux packages are distributed via AppImage.
EOF

if opts && tagged; then
cat << EOF
[zsync](https://zsync.moria.org.uk/) files are provided for easier updating, such as via
[AM](https://github.com/ivan-hc/AM).

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

EOF

if tagged; then
	echo "| Target | amd64 | aarch64 | Notes |"
	echo "|--------|-------|---------|-------|"
else
	echo "| Target | amd64 | Notes |"
	echo "|--------|-------|-------|"
fi

deb_matrix

cat <<EOF

### Room Executables

These are statically linked Linux executables for the \`eden-room\` binary.

EOF

room_matrix

# TODO: setup files
cat << EOF

## Windows

Windows packages are in-place zip files. Setup files are soon to come.
Note that arm64 builds are experimental.

| Compiler | amd64 | arm64 | Notes |
|----------|-------|-------|-------|
EOF

win_matrix

if falsy "$DISABLE_ANDROID"; then
	cat << EOF

## Android

| Build  | Description |
|--------|-------------|
EOF

	android Standard "standard" "Single APK for all supported Android devices (most users should use this)"
	android x86_64 "chromeos" "For devices running Chrome/FydeOS, AVD emulators, or certain Intel Atom Android devices."
	if tagged; then
		android Optimized "optimized" "For any Android device that has Frame Generation or any other per-device feature"
		android Legacy "legacy" "For Adreno A6xx and other older GPUs"
	fi
fi

cat << EOF

## macOS

macOS comes in a tarballed app. These builds are currently experimental, and you should expect major graphical glitches and crashes.
In order to run the app, you *may* need to go to System Settings -> Privacy & Security -> Security -> Allow untrusted app.

| File | Description |
| ---- | ----------- |
| [macOS](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-macOS-${REF}.tar.gz) | For Apple Silicon (M1, M2, etc)|

## Source

Contains all source code, submodules, and CPM cache at the time of release.
This can be extracted with \`tar xf ${PROJECT_PRETTYNAME}-Source-${REF}.tar.zst\`.

| File | Description |
| ---- | ----------- |
| [tar.zst](${BASE_DOWNLOAD_URL}/${TAG}/${PROJECT_PRETTYNAME}-Source-${REF}.tar.zst) | Source as a zstd-compressed tarball (Windows: use Git Bash or MSYS2) |

EOF