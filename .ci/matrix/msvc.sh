#!/bin/sh -e

# TODO(crueter): MSVC PGO? Does ARM work?
AMD64='"runs-on": "windows-latest", "arch": "amd64"'
ARM64='"runs-on": "windows-11-arm", "arch": "arm64"'

PGO='"program": "msvc", "target": "pgo"'
CLANG='"program": "msvc", "target": "standard"'

target() {
	arch="$1"
	compiler="$2"

	echo "{${arch}, ${compiler}}"
}

amd64_msvc="$(target "$AMD64" "$CLANG")"
arm64_msvc="$(target "$ARM64" "$CLANG")"
# MATRIX="[${amd64_msvc}, ${arm64_msvc}]"
MATRIX="[${amd64_msvc}]"

echo "$MATRIX"
echo "matrix=${MATRIX}" >>"$GITHUB_OUTPUT"
