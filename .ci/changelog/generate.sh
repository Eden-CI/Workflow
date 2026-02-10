#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091

WORKFLOW_DIR=$(CDPATH='' cd -P -- "$(dirname -- "$0")/../.." && pwd)
. "$WORKFLOW_DIR/.ci/common/project.sh"

tagged() {
	falsy "$DEVEL"
}

opts() {
	falsy "$DISABLE_OPTS"
}

# FIXME(crueter)
# TODO(crueter): field() func that does linking and such
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
	echo "([Master Build]($MASTER_RELEASE_URL?q=$FORGEJO_PR_MERGE_BASE&expanded=true))"
	echo
	echo "## Changelog"
	.ci/common/field.py field="body" default_msg="No changelog provided" pull_request_number="$FORGEJO_PR_NUMBER"
	;;
tag)
	echo "## Changelog"
	;;
nightly)
	echo "Nightly build of commit [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commits/$FORGEJO_LONGSHA)."
	;;
push | test)
	echo "CI test build"
	;;
esac
echo

# TODO(crueter): Don't include fields if their corresponding artifacts aren't found.

android() {
	TITLE="$1"
	FULL_TARGET="$2"
	DESCRIPTION="$3"

	echo -n "| "
	echo -n "[Android $TITLE](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-Android-${ARTIFACT_REF}-${FULL_TARGET}.apk) | "
	echo "$DESCRIPTION |"
}

src() {
	EXT="$1"
	DESCRIPTION="$2"

	echo -n "| "
	echo -n "[$EXT](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-Source-${ARTIFACT_REF}.${EXT}) | "
	echo -n "$DESCRIPTION |"
	echo
}

linux_field() {
	TARGET="$1"
	PRETTY_TARGET="$2"
	NOTES="${3}"
	gcc_FULL_TARGET="${TARGET}-gcc"
	pgo_FULL_TARGET="${TARGET}-clang-pgo"

	echo -n "| $PRETTY_TARGET | "
	echo -n "[GCC](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-Linux-${ARTIFACT_REF}-${gcc_FULL_TARGET}.AppImage) "
	if tagged; then
		echo -n "([zsync](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-Linux-${ARTIFACT_REF}-${gcc_FULL_TARGET}.AppImage.zsync)) | "
		if opts; then
			echo -n "[PGO](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-Linux-${ARTIFACT_REF}-${pgo_FULL_TARGET}.AppImage) "
			echo -n "([zsync](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-Linux-${ARTIFACT_REF}-${pgo_FULL_TARGET}.AppImage.zsync))"
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

	TARGET=amd64
	tagged && TARGET="$TARGET aarch64"
	for FULL_TARGET in $TARGET; do
		gcc_FULL_TARGET="${TARGET}-gcc"
		echo -n "[$FULL_TARGET](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-$BUILD-${ARTIFACT_REF}-${gcc_FULL_TARGET}.deb) | "
	done

	echo "$NOTES"
}

deb_matrix() {
    deb_field Ubuntu-24.04 "Not compatible with Ubuntu 25.04 or later"
	deb_field Debian-12 "Drivers may be old"
	deb_field Debian-13
}

room_matrix() {
	for TARGET in aarch64 x86_64; do
		FULL_TARGET="$TARGET-musl"
		echo "- [$TARGET](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/eden-room-linux-$FULL_TARGET)"
	done
}

win_field() {
	LABEL="$1"
	COMPILER="$2"
	ARM_COMPILER="$3"
	NOTES="$4"

	echo -n "| $LABEL | "
	[ -n "$COMPILER" ] && echo -n "[amd64](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-Windows-${ARTIFACT_REF}-amd64-${COMPILER}.zip)"
	echo -n " | "
	[ -n "$ARM_COMPILER" ] && echo -n "[arm64](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-Windows-${ARTIFACT_REF}-arm64-${ARM_COMPILER}.zip)"

	echo " | $NOTES"
}

win_matrix() {
	win_field MSVC msvc

	if falsy "$DISABLE_MINGW"; then
		win_field "MinGW (GCC)" gcc "" "May have additional bugs/glitches"
		win_field "MinGW (Clang)" "" clang ""
		opts && tagged && win_field "MinGW (PGO)" clang-pgo clang-pgo "" || true
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

	android Standard "Mainline" "Single APK for all supported Android devices (most users should use this)"
	android x86_64 "ChromeOS" "For devices running Chrome/FydeOS, AVD emulators, or certain Intel Atom Android devices."
	if tagged; then
		android Optimized "GenshinSpoof" "For any Android device that has Frame Generation or any other per-device feature"
		android Legacy "Legacy" "For Adreno A6xx and other older GPUs"
	fi
fi

cat << EOF

## macOS

macOS comes in a tarballed app. These builds are currently experimental, and you should expect major graphical glitches and crashes.
In order to run the app, you *may* need to go to System Settings -> Privacy & Security -> Security -> Allow untrusted app.

| File | Description |
| ---- | ----------- |
| [macOS arm64](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-macOS-${ARTIFACT_REF}-arm64-AppleClang.tar.gz) | For Apple Silicon (M1, M2, etc)|

## Source

Contains all source code, submodules, and CPM cache at the time of release.
This can be extracted with \`tar xf ${PROJECT_PRETTYNAME}-Source-${GITHUB_TAG}.tar.zst\`.

| File | Description |
| ---- | ----------- |
| [tar.zst](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-Source-${ARTIFACT_REF}.tar.zst) | Source as a zstd-compressed tarball (Windows: use Git Bash or MSYS2) |

EOF
