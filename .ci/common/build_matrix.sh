#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

android_matrix() {
	OPT='{"runs-on": "ubuntu-24.04", "flavor": "optimized"}'
	LEG='{"runs-on": "ubuntu-24.04", "flavor": "legacy"}'
	STD='{"runs-on": "ubuntu-24.04", "flavor": "standard"}'
	CHR='{"runs-on": "ubuntu-24.04", "flavor": "chromeos"}'

	if [ "${DEVEL}" = "false" ]; then
		TARGETS="[$OPT, $LEG, $STD, $CHR]"
	else
		TARGETS="[$STD, $CHR]"
	fi

	echo "$TARGETS"
	echo "android=${TARGETS}" >> "$GITHUB_OUTPUT"
}

linux_matrix() {
	RUNS_AMD64='"runs-on": "ubuntu-24.04"'
	RUNS_AARCH64='"runs-on": "ubuntu-24.04-arm"'

	APPIMAGE=' "pretty-name": "AppImage",     "id": "arch",   "system": "linux",        "container": "ghcr.io/pkgforge-dev/archlinux:latest"'
	DEBIAN_12='"pretty-name": "Debian-12",    "id": "debian", "system": "debian-12",    "container": "debian:bookworm"'
	DEBIAN_13='"pretty-name": "Debian-13",    "id": "debian", "system": "debian-13",    "container": "debian:trixie"'
	UBUNTU='   "pretty-name": "Ubuntu-24.04", "id": "debian", "system": "ubuntu-24.04", "container": "ubuntu:noble"'

	AMD64='    "arch": "amd64"'
	AARCH64='  "arch": "aarch64"'
	LEGACY='   "arch": "legacy"'
	ROG_ALLY=' "arch": "rog-ally"'
	STEAMDECK='"arch": "steamdeck"'

	CLANG='"program": "clang", "target": "standard"'
	PGO='  "program": "clang", "target": "pgo"'
	GCC='  "program": "gcc",   "target": "standard"'

	target_linux() {
		runs_on="$1"
		arch="$2"
		system="$3"
		compiler="$4"

		echo "{${runs_on}, ${arch}, ${system}, ${compiler}}"
	}

	# AppImage / AMD64
	amd64_appimage=$(target_linux  "$RUNS_AMD64" "$AMD64"     "$APPIMAGE" "$GCC")
	amd64_steamdeck=$(target_linux "$RUNS_AMD64" "$STEAMDECK" "$APPIMAGE" "$GCC")
	amd64_legacy=$(target_linux    "$RUNS_AMD64" "$LEGACY"    "$APPIMAGE" "$GCC")
	amd64_rogally=$(target_linux   "$RUNS_AMD64" "$ROG_ALLY"  "$APPIMAGE" "$GCC")

	# Debian-like / AMD64
	amd64_ubuntu=$(target_linux   "$RUNS_AMD64" "$AMD64" "$UBUNTU"    "$GCC")
	amd64_debian12=$(target_linux "$RUNS_AMD64" "$AMD64" "$DEBIAN_12" "$GCC")
	adm64_debian13=$(target_linux "$RUNS_AMD64" "$AMD64" "$DEBIAN_13" "$GCC")

	# Clang / AMD64
	amd64_pgo=$(target_linux           "$RUNS_AMD64" "$AMD64"     "$APPIMAGE" "$PGO")
	amd64_pgo_steamdeck=$(target_linux "$RUNS_AMD64" "$STEAMDECK" "$APPIMAGE" "$PGO")
	amd64_pgo_legacy=$(target_linux    "$RUNS_AMD64" "$LEGACY"    "$APPIMAGE" "$PGO")
	amd64_pgo_rogally=$(target_linux   "$RUNS_AMD64" "$ROG_ALLY"  "$APPIMAGE" "$PGO")

	# AppImage / AARCH64
	aarch64_appimage=$(target_linux "$RUNS_AARCH64" "$AARCH64" "$APPIMAGE" "$GCC")
	aarch64_pgo=$(target_linux      "$RUNS_AARCH64" "$AARCH64" "$APPIMAGE" "$PGO")

	# Debian-like / AARCH64
	aarch64_ubuntu=$(target_linux   "$RUNS_AARCH64" "$AARCH64" "$UBUNTU"    "$GCC")
	aarch64_debian12=$(target_linux "$RUNS_AARCH64" "$AARCH64" "$DEBIAN_12" "$GCC")
	aarch64_debian13=$(target_linux "$RUNS_AARCH64" "$AARCH64" "$DEBIAN_13" "$GCC")

	INCLUDE="${amd64_appimage}, ${amd64_ubuntu}, ${amd64_debian12}, ${adm64_debian13}"
	if [ "${DISABLE_ARM}" != "true" ]; then
		INCLUDE="${INCLUDE}, ${aarch64_appimage}, ${aarch64_ubuntu}, ${aarch64_debian12}, ${aarch64_debian13}"
	fi
	if [ "${DEVEL}" != "true" ]; then
		INCLUDE="${INCLUDE}, ${amd64_steamdeck}, ${amd64_legacy}, ${amd64_rogally}"
	fi
	if [ "${DEVEL}" != "true" ] || [ "${FORCE_PGO}" = "true" ]; then
		INCLUDE="${INCLUDE}, ${amd64_pgo}, ${amd64_pgo_steamdeck}, ${amd64_pgo_legacy}, ${amd64_pgo_rogally}"
		if [ "${DISABLE_ARM}" != "true" ]; then
			INCLUDE="${INCLUDE}, ${aarch64_pgo}"
		fi
	fi

	MATRIX="[${INCLUDE}]"
	echo "$MATRIX"
	echo "linux=${MATRIX}" >> "$GITHUB_OUTPUT"
}

windows_matrix() {
	WIN_AMD64='  "pretty-name": "Windows"'
	MINGW_AMD64='"pretty-name": "MINGW64"'
	UCRT64='     "pretty-name": "UCRT64"'
	CLANG_AMD64='"pretty-name": "CLANG64"'
	ARM64='      "pretty-name": "CLANGARM64"'

	CLANG='"program": "clang", "target": "standard"'
	PGO='  "program": "clang", "target": "pgo"'
	GCC='  "program": "gcc",   "target": "standard"'
	UCRT=' "program": "gcc",   "target": "ucrt"'
	MSVC=' "program": "msvc",  "target": "standard"'

	target_windows() {
		arch="$1"
		system="$2"
		prettyname="$3"
		compiler="$4"

		target_arch="\"arch\": \"${arch}\""
		if [ "${arch}" == "aarch64" ]; then
			runs_on='"runs-on": "windows-11-arm"'
		elif [ "${arch}" == "amd64" ]; then
			runs_on='"runs-on": "windows-2025"'
		else
			# Unsupported Arch
			exit 1
		fi

		target_system="\"system\": \"${system}\""
		if [ "${system}" == "mingw" ]; then
			shell='"shell": "msys2"'
		elif [ "${system}" == "windows" ]; then
			shell='"shell": "bash"'
		else
			# Should never happen, but just in case of some Birdbrain
			exit 1
		fi

		echo "{${runs_on}, ${target_arch}, ${target_system}, ${shell}, ${prettyname}, ${compiler}}"
	}

	# Clang / AMD64
	amd64_clang=$(target_windows "amd64" "mingw"   "$CLANG_AMD64" "$CLANG")
	amd64_pgo=$(target_windows   "amd64" "mingw"   "$CLANG_AMD64" "$PGO")

	# Windows / AMD64
	amd64_gcc=$(target_windows "amd64" "mingw"   "$MINGW_AMD64" "$GCC")
	ucrt_gcc=$(target_windows  "amd64" "mingw"   "$UCRT64"      "$UCRT")
	win_msvc=$(target_windows  "amd64" "windows" "$WIN_AMD64"   "$MSVC")

	# Msys / ARM64
	aarch64_clang=$(target_windows "aarch64" "mingw" "$ARM64" "$CLANG")
	aarch64_pgo=$(target_windows   "aarch64" "mingw" "$ARM64" "$PGO")

	INCLUDE="${amd64_gcc}, ${win_msvc}"
	if [ "${DISABLE_ARM}" != "true" ]; then
		INCLUDE="${INCLUDE}, ${aarch64_clang}"
	fi
	if [ "${DEVEL}" != "true" ] || [ "${FORCE_PGO}" = "true" ]; then
		INCLUDE="${INCLUDE}, ${amd64_pgo}"
		if [ "${DISABLE_ARM}" != "true" ]; then
			INCLUDE="${INCLUDE}, ${aarch64_pgo}"
		fi
	fi

	MATRIX="[${INCLUDE}]"
	echo "$MATRIX"
	echo "windows=${MATRIX}" >> "$GITHUB_OUTPUT"
}

android_matrix
linux_matrix
windows_matrix
