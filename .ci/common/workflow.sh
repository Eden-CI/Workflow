#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

: "${DEVEL:=false}"
: "${DISABLE_ARM:=false}"
: "${FORCE_PGO:=false}"

if [ -z "${BASH_VERSION:-}" ]; then
    echo "error: This script MUST be run with bash"
    exit 1
fi

ROOTDIR="$PWD"
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$WORKFLOW_DIR/.ci/common/project.sh"
: "${WORKFLOW_JSON:=$ROOTDIR/workflow.json}"


# Default GitHub Runners
RUNNER='{
	"linux-amd64":		{ "runs_on":	"ubuntu-24.04" },
	"linux-aarch64":	{ "runs_on":	"ubuntu-24.04-arm" },
	"windows-amd64":	{ "runs_on":	"windows-2025" },
	"windows-arm64":	{ "runs_on":	"windows-11-arm" },
	"macos-x64":		{ "runs_on":	"macos-15-large"},
	"macos-arm64":		{ "runs_on":	"macos-latest", "comments": "For Apple Silicon (M1, M2, etc)"}
}'

# Targets
TARGET='{
	"amd64": {
		"target": "amd64",
		"target-name": "AMD64",
		"package-group": "Standard"
	},
	"x86_64": {
		"target": "x86_64",
		"target-name": "x86_64",
		"package-group": "Standard"
	},
	"x64": {
		"target": "x64",
		"target-name": "x64",
		"package-group": "Standard"
	},
	"arm64": {
		"target": "arm64",
		"target-name": "ARM64",
		"package-group": "Standard"
	},
	"aarch64": {
		"target": "aarch64",
		"target-name": "AARCH64",
		"package-group": "Standard"
	},
	"legacy": {
		"target": "legacy",
		"target-name": "Legacy AMD64",
		"comments": "Pre-Ryzen or Haswell CPUs (expect sadness)"
	},
	"rog-ally": {
		"target": "rog-ally",
		"target-name": "ROG Ally X",
		"comments": "Zen 4"
	},
	"steamdeck": {
		"target": "steamdeck",
		"target-name": "Steam Deck",
		"comments": "Zen 2, with additional patches for SteamOS"
	},
	"chromeos": {
		"target": "chromeos",
		"target-name": "x86_64",
		"package-title":"ChromeOS",
		"package-link":"x86_64",
		"comments": "For devices running Chrome/FydeOS, AVD emulators, or certain Intel Atom Android devices."
	},
	"android-standard": {
		"target": "standard",
		"target-name": "standard",
		"package-title":"Standard",
		"package-link":"Mainline",
		"comments": "Single APK for all supported Android devices (most users should use this)"
	},
	"android-legacy": {
		"target": "legacy",
		"target-name": "legacy",
		"package-title":"Legacy",
		"package-link":"Legacy",
		"comments": "For Adreno A6xx and other older GPUs"
	},
	"android-optimized": {
		"target": "optimized",
		"target-name": "optimized",
		"package-title":"Optimized",
		"package-link":"GenshinSpoof",
		"comments": "For any Android device that has Frame Generation or any other per-device feature"
	}
}'

# Compilers
COMPILER='{
	"msvc": {
		"compiler-pretty": "MSVC",
		"compiler": "msvc"
	}, "gcc": {
		"compiler-pretty": "GCC",
		"compiler": "gcc"
	}, "ucrt": {
		"compiler-pretty": "UCRT",
		"compiler": "gcc",
		"compiler-opt": "-ucrt"
	}, "clang": {
		"compiler-pretty": "Clang",
		"compiler": "clang"
	}, "pgo": {
		"compiler-pretty": "PGO",
		"compiler": "clang",
		"compiler-opt": "-pgo"
	}, "appleclang": {
		"compiler-pretty": "AppleClang",
		"compiler": "clang"
	}, "none": {
		"compiler-pretty": ""
	}
}'

# Default System Runners
SYSTEM='{
	"linux": {
		"id": "linux",
		"system": "linux",
		"system-pretty": "Linux",
		"container": "ghcr.io/pkgforge-dev/archlinux:latest",
		"package-extension": ".AppImage",
		"package-extra": ".zsync",
		"comments": "[RECOMMENDED] Most users should use this"
	}, "ubuntu": {
		"id": "debian",
		"system": "ubuntu-24.04",
		"system-pretty": "Ubuntu 24.04",
		"container": "ubuntu:noble",
		"package-extension": ".deb",
		"comments": "Not compatible with Ubuntu 25.04 or later"
	}, "debian-12": {
		"id": "debian",
		"system": "debian-12",
		"system-pretty": "Debian 12",
		"container": "debian:bookworm",
		"package-extension": ".deb",
		"comments": "Drivers may be old"
	}, "debian-13": {
		"id": "debian",
		"system": "debian-13",
		"system-pretty": "Debian 13",
		"container": "debian:trixie",
		"package-extension": ".deb"
	}, "windows": {
		"id": "windows",
		"system": "windows",
		"system-pretty": "Windows",
		"shell": "bash",
		"package-extension": ".zip",
		"comments": "[RECOMMENDED] Most users should use this"
	}, "mingw64": {
		"id": "mingw",
		"system": "mingw",
		"system-pretty": "MINGW64",
		"shell": "msys2",
		"package-extension": ".zip",
		"comments": "May have additional bugs/glitches"
	}, "ucrt64": {
		"id": "mingw",
		"system": "ucrt",
		"system-pretty": "UCRT64",
		"shell": "msys2",
		"package-extension": ".zip"
	}, "clang64": {
		"id": "mingw",
		"system": "clang",
		"system-pretty": "CLANG64",
		"shell": "msys2",
		"package-extension": ".zip"
	}, "clangarm64": {
		"id": "mingw",
		"system": "clangarm",
		"system-pretty": "CLANGARM64",
		"shell": "msys2",
		"package-extension": ".zip"
	}, "alpine": {
		"id": "alpine",
		"system": "room",
		"system-pretty": "Room",
		"container": "alpine:3.23",
		"package-group": "linux"
	}, "macos": {
		"id": "macos",
		"system": "macos",
		"system-pretty": "macOS",
		"package-extension": ".tar.gz"
	}, "freebsd": {
		"id": "freebsd",
		"system": "freebsd",
		"system-pretty": "FreeBSD",
		"package-extension": ".tar.zst"
	}, "android": {
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
		--argjson compiler "$(lookup "$COMPILER" "$_compiler")" \
		--argjson target "$(lookup "$TARGET" "$_target")" \
		'(if $system["id"] == "android" then
				$target["target-name"]
			elif $system["id"] == "alpine" then
				$system["package-group"] + "-" + $target["target"] + "-musl"
			else
				$target["target"] + "-" + $compiler["compiler"] + ($compiler["compiler-opt"] // "")
			end) as $package_target |
		(if $system["package-extension"] then $system["package-extension"] else "" end) as $package_extension |
		$system + {
			"runs-on":		($runner["runs_on"]),
			"target":		($target["target"]),
			"compiler":		($compiler["compiler"] // ""),
			"compiler-opt":	($compiler["compiler-opt"] // ""),
			"package-title":
				(if $system["id"] == "linux" then
					(if $target["package-group"] == "Standard" then
						$target["package-group"]
					else
						$target["target-name"]
					end)
				elif $system["id"] == "windows" then
					$compiler["compiler-pretty"]
				elif $system["id"] == "mingw" then
					$compiler["compiler-pretty"]
				elif $system["id"] == "android" then
					$target["package-title"]
				else
					$system["system-pretty"]
				end),
			"package-link":
				(if $system["id"] == "linux" then
					$compiler["compiler-pretty"]
				elif $system["id"] == "android" then
					$target["package-link"]
				else
					$target["target"]
				end),
			"package-extension":	($package_extension),
			"package-extra":		(if $system["package-extra"] then $system["package-extra"] else "" end),
			"package-target":		($package_target),
			"package-final":		($project_prettyname +"-"+ ($system["system"] | gsub("\\s+"; "-")) +"-"+ $artifact_ref +"-"+ $package_target + $package_extension),
			"container":	($system["container"] // ""),
			"shell":		($system["shell"] // ""),
			"comments": ($target["comments"] // $compiler["comments"] // $system["comments"] // $runner["comments"] // "")
		}'
}

android_matrix() {
	android_std=$(json_build	linux-amd64	android	android-standard	none)
	android_chr=$(json_build	linux-amd64	android	chromeos			none)
	android_leg=$(json_build	linux-amd64	android	android-legacy		none)
	android_opt=$(json_build	linux-amd64	android	android-optimized	none)

	INCLUDE="$android_std $android_chr"
	if falsy "$DEVEL"; then
		INCLUDE="$INCLUDE $android_leg $android_opt"
	fi

	MATRIX=$(jq -s '.' <<<"$INCLUDE")
	jq . <<<"$MATRIX"
	if truthy "${CI}"; then echo "android=$(jq -c . <<<"$MATRIX")" >> "$GITHUB_OUTPUT"; fi
}

linux_pgo_matrix() {
	# Clang + PGO / AMD64
	amd64_pgo_standard=$(json_build		linux-amd64	linux	amd64		pgo)
	amd64_pgo_steamdeck=$(json_build	linux-amd64	linux	steamdeck	pgo)
	amd64_pgo_legacy=$(json_build		linux-amd64	linux	legacy		pgo)
	amd64_pgo_rogally=$(json_build		linux-amd64	linux	rog-ally	pgo)

	# AppImage / AARCH64
	aarch64_pgo=$(json_build		linux-aarch64	linux	aarch64	pgo)

	INCLUDE="$amd64_pgo_standard $amd64_pgo_steamdeck"
	if falsy "$DEVEL"; then
		INCLUDE="$INCLUDE $amd64_pgo_legacy $amd64_pgo_rogally"
	fi
	if falsy "$DISABLE_ARM"; then
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
	if falsy "$DISABLE_ARM"; then
		INCLUDE="$INCLUDE $aarch64_appimage"
	fi
	if falsy "$DEVEL"; then
		INCLUDE="$INCLUDE $amd64_legacy $amd64_rogally"
		if falsy "$DISABLE_ARM"; then
			INCLUDE="$INCLUDE $aarch64_ubuntu $aarch64_debian12 $aarch64_debian13"
		fi
	fi

	if falsy "$DEVEL" || truthy "$FORCE_PGO"; then
		INCLUDE="$INCLUDE $(linux_pgo_matrix)"
	fi

	MATRIX=$(jq -s '.' <<<"$INCLUDE")
	jq . <<<"$MATRIX"
	if truthy "${CI}"; then echo "linux=$(jq -c . <<<"$MATRIX")" >> "$GITHUB_OUTPUT"; fi
}

windows_matrix() {
	# AMD64
	amd64_gcc=$(json_build	windows-amd64	mingw64		amd64	gcc)
	win_msvc=$(json_build	windows-amd64	windows	amd64	msvc)

	# ARM64
	aarch64_clang=$(json_build	windows-arm64	clangarm64	arm64	clang)

	INCLUDE="$amd64_gcc $win_msvc"
	if falsy "$DISABLE_ARM"; then
		INCLUDE="$INCLUDE $aarch64_clang"
	fi

	if falsy "$DEVEL" || truthy "$FORCE_PGO"; then
		INCLUDE="$INCLUDE $(windows_pgo_matrix)"
	fi

	MATRIX=$(jq -s '.' <<<"$INCLUDE")
	jq . <<<"$MATRIX"
	if truthy "${CI}"; then echo "windows=$(jq -c . <<<"$MATRIX")" >> "$GITHUB_OUTPUT"; fi
}

windows_pgo_matrix() {
	# AMD64
	amd64_pgo=$(json_build	windows-amd64	clang64	amd64	pgo)

	# ARM64
	aarch64_pgo=$(json_build	windows-arm64	clangarm64	arm64	pgo)

	INCLUDE="$amd64_pgo"
	if falsy "$DISABLE_ARM"; then
		INCLUDE="$INCLUDE $aarch64_pgo"
	fi

	jq -c . <<<"$INCLUDE"
}

linux_room_matrix(){
	amd64_room=$(json_build		linux-amd64		alpine	x86_64	gcc)
	aarch64_room=$(json_build	linux-aarch64	alpine	aarch64	gcc)

	INCLUDE="$amd64_room"
	if falsy "$DISABLE_ARM"; then
		INCLUDE="$INCLUDE $aarch64_room"
	fi

	MATRIX=$(jq -s '.' <<<"$INCLUDE")
	jq . <<<"$MATRIX"
	if truthy "${CI}"; then echo "room=$(jq -c . <<<"$MATRIX")" >> "$GITHUB_OUTPUT"; fi
}

macos_matrix(){
	x64_macos=$(json_build	macos-x64	macos	x64		appleclang)
	arm64_macos=$(json_build	macos-arm64	macos	arm64	appleclang)

	INCLUDE="$arm64_macos"
# 	INCLUDE="$x64_macos"
# 	if falsy "$DISABLE_ARM"; then
# 		INCLUDE="$INCLUDE $arm64_macos"
# 	fi

	MATRIX=$(jq -s '.' <<<"$INCLUDE")
	jq . <<<"$MATRIX"
	if truthy "${CI}"; then echo "macos=$(jq -c . <<<"$MATRIX")" >> "$GITHUB_OUTPUT"; fi
}

freebsd_matrix() {
	amd64_freebsd=$(json_build linux-amd64 freebsd amd64 clang)

	INCLUDE="$amd64_freebsd"
	MATRIX=$(jq -s '.' <<<"$INCLUDE")
	jq . <<<"$MATRIX"
	if truthy "${CI}"; then echo "freebsd=$(jq -c . <<<"$MATRIX")" >> "$GITHUB_OUTPUT"; fi
}

jq -n -s \
	--argjson android "$(android_matrix)" \
	--argjson linux "$(linux_matrix)" \
	--argjson windows "$(windows_matrix)" \
	--argjson room "$(linux_room_matrix)" \
	--argjson macos "$(macos_matrix)" \
	--argjson freebsd "$(freebsd_matrix)" \
	'{
		android: $android,
		linux: $linux,
		windows: $windows,
		room: $room,
		macos: $macos,
		freebsd: $freebsd
	}' > "$WORKFLOW_JSON"
