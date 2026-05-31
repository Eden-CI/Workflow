#!/bin/sh -e

use_extra() {
	[ "$DEVEL" != "true" ] || [ "$FORCE_PGO" = "true" ]
}

## Architectures ##
arch() {
	cat <<-EOF
		{"runs-on": "$1", "arch": "$2"}
	EOF
}

amd=$(arch ubuntu-latest amd64)
arm=$(arch ubuntu-24.04-arm aarch64)

legacy=$(arch ubuntu-latest legacy)
steam=$(arch ubuntu-latest steamdeck)
ally=$(arch ubuntu-latest rog-ally)

arches="[$amd, $arm"
if use_extra; then
	arches="$arches, $legacy, $steam, $ally"
fi
arches="$arches]"

echo "Architectures: $arches"
echo "matrix=${arches}" >>"$GITHUB_OUTPUT"

## Compilers ##

compiler() {
	cat <<-EOF
		{"program": "$1", "target": "$2"}
	EOF
}

gcc=$(compiler gcc standard)
pgo=$(compiler clang pgo)

compilers="[$gcc"

if use_extra; then
	compilers="$compilers, $pgo"
fi

compilers="$compilers]"

echo "Compilers: $compilers"
echo "compiler=${compilers}" >>"$GITHUB_OUTPUT"
