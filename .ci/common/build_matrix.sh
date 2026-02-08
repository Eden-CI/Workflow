#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

: "${DEVEL:=false}"
: "${DISABLE_ARM:=false}"
: "${FORCE_PGO:=false}"

# Default GitHub Runners
RUNNER='{
	"linux-amd64":		{ "runs_on":	"ubuntu-24.04" },
	"linux-aarch64":	{ "runs_on":	"ubuntu-24.04-arm" },
	"windows-amd64":	{ "runs_on":	"windows-2025" },
	"windows-arm64":	{ "runs_on":	"windows-11-arm" }
}'

# Targets
TARGET='{
	"amd64":		{ "target": "amd64",		"target-name": "AMD64" },
	"arm64":		{ "target": "arm64",		"target-name": "ARM64" },
	"aarch64":		{ "target": "aarch64",		"target-name": "AARCH64" },
	"legacy":		{ "target": "legacy",		"target-name": "Legacy AMD64" },
	"rog-ally":		{ "target": "rog-ally",		"target-name": "ROG Ally X" },
	"steamdeck":	{ "target": "steamdeck",	"target-name": "Steam Deck" },
	"chromeos":		{ "target": "chromeos",		"target-name": "x86_64" },
	"android-standard":		{ "target": "standard",		"target-name": "standard" },
	"android-legacy":		{ "target": "legacy",		"target-name": "legacy" },
	"android-optimized":	{ "target": "optimized",	"target-name": "optimized" }
}'

# Compilers
COMPILER='{
	"gcc":		{ "compiler-pretty": "GCC",		"compiler": "gcc" },
	"ucrt":		{ "compiler-pretty": "UCRT",	"compiler": "gcc", "compiler-opt": "-ucrt" },
	"clang":	{ "compiler-pretty": "Clang",	"compiler": "clang" },
	"pgo":		{ "compiler-pretty": "PGO",		"compiler": "clang", "compiler-opt": "-pgo" },
	"msvc":		{ "compiler-pretty": "MSVC",	"compiler": "msvc" },
	"none":		{ "compiler-pretty": "" }
}'

# Default System Runners
SYSTEM='{
	"linux": {
		"id": "linux",
		"system": "linux",
		"system-pretty": "Linux",
		"container": "ghcr.io/pkgforge-dev/archlinux:latest",
		"package-extension": ".AppImage",
		"package-extra": ".zsync"
	},
	"ubuntu": {
		"id": "debian",
		"system": "ubuntu-24.04",
		"system-pretty": "Ubuntu 24.04",
		"container": "ubuntu:noble",
		"package-extension": ".deb"
	},
	"debian-12": {
		"id": "debian",
		"system": "debian-12",
		"system-pretty": "Debian 12",
		"container": "debian:bookworm",
		"package-extension": ".deb"
	},
	"debian-13": {
		"id": "debian",
		"system": "debian-13",
		"system-pretty": "Debian 13",
		"container": "debian:trixie",
		"package-extension": ".deb"
	},
	"windows": {
		"id": "windows",
		"system": "windows",
		"system-pretty": "Windows",
		"shell": "bash",
		"package-extension": ".exe"
	},
	"mingw64": {
		"id": "mingw",
		"system": "mingw",
		"system-pretty": "MINGW64",
		"shell": "msys2",
		"package-extension": ".exe"
	},
	"ucrt64": {
		"id": "mingw",
		"system": "ucrt",
		"system-pretty": "UCRT64",
		"shell": "msys2",
		"package-extension": ".exe"
	},
	"clang64": {
		"id": "mingw",
		"system": "clang",
		"system-pretty": "CLANG64",
		"shell": "msys2",
		"package-extension": ".exe"
	},
	"clangarm64": {
		"id": "mingw",
		"system": "clangarm",
		"system-pretty": "CLANGARM64",
		"shell": "msys2",
		"package-extension": ".exe"
	},
	"android": {
		"id": "android",
		"system": "android",
		"system-pretty": "Android",
		"package-extension": ".apk"
	}
}'

lookup() {
	json="$1"
	key="$2"

	jq -n \
		--argjson data "$json" \
		--arg key "$key" \
		'$data[$key]'
}

json_build() {
	_runner="$1"
	_system="$2"
	_target="$3"
	_compiler="$4"

	jq -c -n \
		--arg project_prettyname "${PROJECT_PRETTYNAME}" \
		--arg artifact_ref "${ARTIFACT_REF}" \
		--argjson runner "$(lookup "$RUNNER" "$_runner")" \
		--argjson system "$(lookup "$SYSTEM" "$_system")" \
		--argjson target "$(lookup "$TARGET" "$_target")" \
		--argjson compiler "$(lookup "$COMPILER" "$_compiler")" \
		'
		(
			if $system["id"] == "linux" then
				$target["target"] + "-" + $compiler["compiler"] + ($compiler["compiler-opt"] // "")
			elif $system["id"] == "debian" then
				$target["target"] + "-" + $compiler["compiler"] + ($compiler["compiler-opt"] // "")
			elif $system["id"] == "windows" then
				$target["target"] + "-" + $compiler["compiler"] + ($compiler["compiler-opt"] // "")
			elif $system["id"] == "mingw" then
				$target["target"] + "-" + $compiler["compiler"] + ($compiler["compiler-opt"] // "")
			elif $system["id"] == "android" then
				$target["target-name"]
			end
		) as $package_target |
		(
			if $system["package-extension"] then $system["package-extension"] else "" end
		) as $package_extension |
		{
			"runs-on":		$runner["runs_on"]
		} + $system + {
			"target":		$target["target"],
			"compiler":		($compiler["compiler"] // ""),
			"compiler-opt":	($compiler["compiler-opt"] // ""),
			"package-title":
				(if $system["id"] == "linux" then
					$target["target-name"]
				elif $system["id"] == "debian" then
					$system["system-pretty"]
				elif $system["id"] == "windows" then
					$compiler["compiler-pretty"]
				elif $system["id"] == "mingw" then
					$compiler["compiler-pretty"]
				elif $system["id"] == "android" then
					"Android " + ($target["target-name"] | (.[0:1] | ascii_upcase) + .[1:])
				end),
			"package-extension":	$package_extension,
			"package-extra":(if $system["package-extra"] then $system["package-extra"] else "" end),
			"package-target": $package_target
				,
			"package-final": ($project_prettyname +"-"+ ($system["system"] | gsub("\\s+"; "-")) +"-"+ $artifact_ref +"-"+ $package_target + $package_extension),
			"container":	($system["container"] // ""),
			"shell":		($system["shell"] // "")
		}'
}

android_matrix() {
	android_std=$(json_build	linux-amd64	android	android-standard	none)
	android_chr=$(json_build	linux-amd64	android	chromeos			none)
	android_leg=$(json_build	linux-amd64	android	android-legacy		none)
	android_opt=$(json_build	linux-amd64	android	android-optimized	none)

	INCLUDE="$android_std $android_chr"
	if [ "$DEVEL" = "false" ]; then
		INCLUDE="$INCLUDE $android_leg $android_opt"
	fi

	MATRIX=$(jq -s '.' <<<"$INCLUDE")
	echo "Android Matrix"
	jq . <<<"$MATRIX"
	if [ "${CI:-}" = "true" ]; then echo "android=$(jq -c . <<<"$MATRIX")" >> "$GITHUB_OUTPUT"; fi
}

linux_pgo_matrix() {
	# Clang + PGO / AMD64
	amd64_pgo_standard=$(json_build		linux-amd64	linux	amd64		pgo)
	amd64_pgo_steamdeck=$(json_build	linux-amd64	linux	steamdeck	pgo)
	amd64_pgo_legacy=$(json_build		linux-amd64	linux	legacy		pgo)
	amd64_pgo_rogally=$(json_build		linux-amd64	linux	rog-ally	pgo)

	# AppImage / AARCH64
	aarch64_pgo=$(json_build		linux-aarch64	linux	aarch64	pgo)

	INCLUDE="$amd64_pgo_standard $amd64_pgo_steamdeck $amd64_pgo_legacy $amd64_pgo_rogally"
	if [ "$DISABLE_ARM" != "true" ]; then
		INCLUDE="$INCLUDE $aarch64_pgo"
	fi

	jq -c . <<<"$INCLUDE"
}

linux_matrix() {
	# AppImage / AMD64
	amd64_standard=$(json_build		linux-amd64	linux	amd64		gcc)
	amd64_steamdeck=$(json_build	linux-amd64	linux	steamdeck	gcc)
	amd64_legacy=$(json_build		linux-amd64	linux	legacy		gcc)
	amd64_rogally=$(json_build		linux-amd64	linux	rog-ally	gcc)

	# AppImage / AARCH64
	aarch64_appimage=$(json_build	linux-aarch64	linux	aarch64	gcc)

	# Debian-like / AMD64
	amd64_ubuntu=$(json_build	linux-amd64	ubuntu		amd64	gcc)
	amd64_debian12=$(json_build	linux-amd64	debian-12	amd64	gcc)
	amd64_debian13=$(json_build	linux-amd64	debian-13	amd64	gcc)

	# Debian-like / AARCH64
	aarch64_ubuntu=$(json_build		linux-aarch64	ubuntu		aarch64	gcc)
	aarch64_debian12=$(json_build	linux-aarch64	debian-12	aarch64	gcc)
	aarch64_debian13=$(json_build	linux-aarch64	debian-13	aarch64	gcc)

	INCLUDE="$amd64_standard $amd64_steamdeck $amd64_ubuntu $amd64_debian12 $amd64_debian13"
	if [ "$DISABLE_ARM" != "true" ]; then
		INCLUDE="$INCLUDE $aarch64_appimage"
	fi
	if [ "$DEVEL" != "true" ]; then
		INCLUDE="$INCLUDE $amd64_legacy $amd64_rogally"
		if [ "$DISABLE_ARM" != "true" ]; then
			INCLUDE="$INCLUDE $aarch64_ubuntu $aarch64_debian12 $aarch64_debian13"
		fi
	fi

	if [ "$DEVEL" != "true" ] || [ "$FORCE_PGO" = "true" ]; then
		INCLUDE="$INCLUDE $(linux_pgo_matrix)"
	fi

	MATRIX=$(jq -s '.' <<<"$INCLUDE")
	echo "Linux Matrix"
	jq . <<<"$MATRIX"
	if [ "${CI:-}" = "true" ]; then echo "linux=$(jq -c . <<<"$MATRIX")" >> "$GITHUB_OUTPUT"; fi
}

windows_matrix() {
	# AMD64
	amd64_gcc=$(json_build	windows-amd64	mingw64		amd64	gcc)
	win_msvc=$(json_build	windows-amd64	windows	amd64	msvc)

	# ARM64
	aarch64_clang=$(json_build	windows-arm64	clangarm64	arm64	clang)

	INCLUDE="$amd64_gcc $win_msvc"
	if [ "$DISABLE_ARM" != "true" ]; then
		INCLUDE="$INCLUDE $aarch64_clang"
	fi

	if [ "$DEVEL" != "true" ] || [ "$FORCE_PGO" = "true" ]; then
		INCLUDE="$INCLUDE $(windows_pgo_matrix)"
	fi

	MATRIX=$(jq -s '.' <<<"$INCLUDE")
	echo "Windows Matrix"
	jq . <<<"$MATRIX"
	if [ "${CI:-}" = "true" ]; then echo "windows=$(jq -c . <<<"$MATRIX")" >> "$GITHUB_OUTPUT"; fi
}

windows_pgo_matrix() {
	# AMD64
	amd64_pgo=$(json_build	windows-amd64	clang64	amd64	pgo)

	# ARM64
	aarch64_pgo=$(json_build	windows-arm64	clangarm64	arm64	pgo)

	INCLUDE="$amd64_pgo"
	if [ "$DISABLE_ARM" != "true" ]; then
		INCLUDE="$INCLUDE $aarch64_pgo"
	fi

	jq -c . <<<"$INCLUDE"
}

# Run it in parallel
android_matrix &
linux_matrix &
windows_matrix &
wait
