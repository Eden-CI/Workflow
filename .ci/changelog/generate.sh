#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091

. ./.ci/common/project.sh

opts() {
	falsy "$DISABLE_OPTS"
}

devel=true

# FIXME(crueter)
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
	python3 .ci/common/field.py field="body" default_msg="No changelog provided" pull_request_number="$FORGEJO_PR_NUMBER"
	;;
tag)
	echo "## Changelog"
	devel=false
	;;
nightly)
	echo "Nightly build of commit [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/compare/$FORGEJO_BEFORE..$FORGEJO_LONGSHA)."
	echo
	cat nightly-changelog.md
	devel=false
	;;
push | test)
	echo "CI test build"
	;;
esac
echo

tagged() {
	falsy "$devel"
}

# create a link
# $1: the label
# $2: the artifact suffix (e.g. PROJECT-Linux-amd64... would just pass in Linux-amd64...)
# $3: optional prefix (defaults to PROJECT_PRETTYNAME)
file_link() {
	label="$1"
	artifact="$2"
	prefix="${3:-$PROJECT_PRETTYNAME}"

	url="$GITHUB_DOWNLOAD/$GITHUB_TAG/$prefix-$artifact"

	printf "[%s](%s)" "$label" "$url"
}

# TODO(crueter): Don't include fields if their corresponding artifacts aren't found.

android() {
	type="$1"
	flavor="$2"
	notes="$3"

	printf "| "
	file_link "$type" "Android-${ARTIFACT_REF}-${flavor}.apk"
	echo " | $notes |"
}

linux_field() {
	arch="$1"
	pretty_arch="$2"
	notes="${3}"

	printf "| %s | " "$pretty_arch"
	file_link "Standard AppImage" "Linux-${ARTIFACT_REF}-${arch}-gcc-standard.AppImage"

	if tagged; then
		printf " ("
		file_link "zsync" "Linux-${arch}-gcc-standard.AppImage.zsync"
		printf ") | "

		if opts; then
			file_link "PGO AppImage" "Linux-${ARTIFACT_REF}-${arch}-clang-pgo.AppImage"
			printf " ("
			file_link "zsync" "Linux-${arch}-clang-pgo.AppImage.zsync"
			printf ")"
		fi
	fi

	echo " | $notes |"
}

linux_matrix() {
	linux_field amd64 "amd64"
	if opts; then
		tagged && linux_field legacy "Legacy amd64" "Pre-Ryzen or Haswell CPUs (expect sadness)"
		linux_field steamdeck "Steam Deck" "Zen 2, with patches for Game/Desktop mode support"
		tagged && linux_field rog-ally "ROG Ally X" "Zen 4, with patches for Game/Desktop mode support"
	fi

	falsy "$DISABLE_ARM" && linux_field aarch64 "ARM (aarch64)"
}

room_matrix() {
	for arch in aarch64 x86_64; do
		echo "- $(file_link "$arch" "room-${arch}-unknown-linux-musl" "eden")"
	done
}

msvc_field() {
	printf "| amd64/x86_64 (MSVC) | "
	file_link "MSVC zip" "Windows-${ARTIFACT_REF}-amd64-msvc-standard.zip"
	if tagged && opts; then
		printf " | "
	fi

	echo " | Use if you encounter graphical issues on other builds (e.g. Pokemon Scarlet & Violet) |"
}

cat <<EOF
Desc, Standard, PGO, notes
amd64-v3, amd64-gcc-standard, amd64-clang-pgo, Requires 4th generation Intel, Ryzen, or newer
Zen 4, rog-ally-gcc-standard, rog-ally-clang-pgo, Requires Zen 4 or newer (e.g. ROG Ally X, Legion Go S)
aarch64/arm64, arm64-clang-standard, arm64-clang-pgo, Snapdragon devices
EOF

win_field() {
	arch="$1"
	pretty_arch="$2"
	notes="$3"

	if [ "$arch" = arm64 ]; then
		compiler=clang
	else
		compiler=gcc
	fi

	printf "| %s | " "$pretty_arch"
	file_link "Standard zip" "Windows-${ARTIFACT_REF}-${arch}-${compiler}-standard.zip"

	if tagged && opts; then
		file_link "PGO zip" "Windows-${ARTIFACT_REF}-${arch}-clang-pgo.AppImage"
	fi

	echo " | $notes |"
}

win_matrix() {
	msvc_field
	win_field amd64 "amd64/x86_64 v3" "Built with MinGW. Requires Ryzen, 4th gen Intel, or newer"
	win_field rog-ally "Zen 4" "Requires Zen 4 or newer. Incompatible with Intel"
	win_field arm64 "aarch64/arm64" "Snapdragon devices"
}

echo "# Packages"

if truthy "$EXPLAIN_TARGETS"; then
	cat <<-EOF

		## Targets

		Each build is optimized for a specific architecture and uses a specific compiler.

		- **aarch64/arm64**: For devices that use the armv8-a instruction set; e.g. Snapdragon X, all Android devices, and Apple Silicon Macs.
		- **amd64**: For devices that use the amd64 (aka x86_64) instruction set; this is exclusively used by Intel and AMD CPUs and is only found on desktops.
		- **v3**: For devices that use the x86_64-v3 instruction set or newer; this is found on Ryzen, Intel 4th Generation (Haswell), and newer.

		### PGO

		PGO builds usually perform ~10-30% better than standard builds, and are thus generally recommended for all users.
	EOF
fi

cat <<EOF

## Linux

Linux packages are distributed via AppImage.
EOF

if opts && tagged; then
	cat <<-EOF
		[zsync](https://zsync.moria.org.uk/) files are provided for easier updating, such as via
		[AM](https://github.com/ivan-hc/AM).

		| Build Type | Standard | PGO (Recommended) | Notes |
		|------------|----------|-----------|-------|
	EOF
else
	cat <<-EOF

		| Build Type |  | Notes |
		|------------|--|-------|
	EOF
fi

linux_matrix

if [ "$1" = "tag" ]; then
	cat <<-EOF

		### Room Executables

		These are statically linked Linux executables for the \`eden-room\` binary.

	EOF

	room_matrix
fi

# TODO: setup files
cat <<EOF

## Windows

Windows packages are in-place zip files. Setup files are soon to come.

EOF

if opts && tagged; then
	cat <<-EOF
		| Build Type | Standard | PGO (Recommended) | Notes |
		|------------|----------|-------------------|-------|
	EOF
else
	cat <<-EOF

		| Build Type |  | Notes |
		|------------|--|-------|
	EOF
fi

win_matrix

if falsy "$DISABLE_ANDROID"; then
	cat <<-EOF

		## Android

		| Build  | Notes |
		|--------|-------|
	EOF

	android "Standard APK" "standard" "The standard build. Most users should use this."

	if tagged; then
		android "Genshin Spoof APK" "optimized" "Spoofs Eden as Genshin Impact, which may enable optimizations/frame generation on some flagship devices."
		android "Legacy APK" "legacy" "For Snapdragon 865 and other unsupported chipsets"
	fi
fi

cat <<EOF

## macOS

macOS comes in a DMG image. These builds are currently experimental, and you should expect major graphical glitches and crashes.
In order to run the app, you *may* need to go to System Settings -> Privacy & Security -> Security -> Allow untrusted app.

EOF

printf -- "- "
file_link "macOS DMG" "macOS-${ARTIFACT_REF}.dmg"
echo

if [ "$1" = "tag" ]; then
	cat <<-EOF
		## Torrent

		A torrent containing all artifacts. To use this, simply download the torrent and import it into your favorite torrent client (BitTorrent only!),
		and artifacts will be downloaded automatically.

		- [Torrent](${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-${ARTIFACT_REF}.torrent)
	EOF
fi
