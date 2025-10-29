#!/bin/sh -e

if command -v sudo >/dev/null 2>&1 ; then
    SUDO="sudo"
fi

if [ "$CI" = "true" ]; then
	MANDB=/var/lib/man-db/auto-update
	[ -f "$MANDB" ] && $SUDO rm "$MANDB"
fi

$SUDO apt update
$SUDO apt -y build-dep .
