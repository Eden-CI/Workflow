#!/bin/sh -e

# TODO: refactor all existing matrix scripts to this style

use_extra() {
	[ "$DEVEL" != "true" ] || [ "$FORCE_PGO" = "true" ]
}

first=1
flavor() {
	[ "$first" -eq 1 ] && first=0 || printf ','
	printf '{"flavor": "%s", "target": "%s"}' "$1" "$2"
}

flavors="standard"
pgo="standard"

if use_extra; then
	flavors="standard legacy optimized"
	# pgo="standard pgo"
fi

printf '['

for flv in $flavors; do
	for tgt in $pgo; do
		flavor "$flv" "$tgt"
	done
done

echo ']'
