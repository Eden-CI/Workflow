#!/bin/sh -e

# Currently uses MINGW64. Could try clang64 or ucrt64,
# but not viable right now.

arch() {
	cat <<-EOF
		"runs-on": "$1", "arch": "$2", "msystem": "$3"
	EOF
}

AMD64="$(arch windows-latest amd64 MINGW64)"
ALLY="$(arch windows-latest rog-ally MINGW64)"
ARM64="$(arch windows-11-arm arm64 CLANGARM64)"

PGO='"program": "clang", "target": "pgo"'
CLANG='"program": "clang", "target": "standard"'
GCC='"program": "gcc", "target": "standard"'

target() {
	arch="$1"
	compiler="$2"

	echo "{${arch}, ${compiler}}"
}

# TODO(crueter): dedupe in some way
# TODO(crueter): Probably don't need legacy?
amd_gcc="$(target "$AMD64" "$GCC")"
amd_pgo="$(target "$AMD64" "$PGO")"
ally_gcc="$(target "$ALLY" "$GCC")"
ally_pgo="$(target "$ALLY" "$PGO")"
arm_clang="$(target "$ARM64" "$CLANG")"
arm_pgo="$(target "$ARM64" "$PGO")"

MATRIX="[${amd_gcc}, ${arm_clang}"
if [ "$DEVEL" != "true" ] || [ "${FORCE_PGO}" = "true" ]; then
	MATRIX="$MATRIX, ${amd_pgo}, ${ally_gcc}, ${ally_pgo}, ${arm_pgo}"
fi

MATRIX="$MATRIX]"

echo "$MATRIX"
echo "matrix=${MATRIX}" >>"$GITHUB_OUTPUT"
