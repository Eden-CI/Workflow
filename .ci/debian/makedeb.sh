#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later
ROOTDIR="$PWD"
BUILDDIR="/build"
BUILDUSER="build"
DIR=$0; [ -n "${BASH_VERSION-}" ] && DIR="${BASH_SOURCE[0]}"; WORKFLOW_DIR="$(cd "$(dirname -- "$DIR")/../.." && pwd)"

# Use sudo if available, otherwise run directly
if command -v sudo >/dev/null 2>&1 ; then
	SUDO=sudo
fi

if command -v apt >/dev/null 2>&1 ; then
	$SUDO apt update
	$SUDO apt install -y asciidoctor binutils build-essential curl fakeroot file \
		gettext gawk libarchive-tools lsb-release python3 python3-apt zstd mold
fi

# if in a container (does not have sudo), make a build user and run as that
if ! command -v sudo > /dev/null 2>&1 ; then
	apt install -y sudo

	sudo useradd -m -s /bin/bash -d "$BUILDDIR" "$BUILDUSER"
	echo "$BUILDUSER ALL=NOPASSWD: ALL" >> /etc/sudoers

	# copy workspace stuff over
	cp -r "$ROOTDIR/"* "$ROOTDIR/.patch" "$ROOTDIR/.ci" "$ROOTDIR/.reuse" "$BUILDDIR"
	if [ -d "$ROOTDIR/.cache" ]; then
		cp -r "$ROOTDIR/.cache" "$BUILDDIR"
		rm -rf "$ROOTDIR/.cache"
		chown -R "$BUILDUSER:$BUILDUSER" "$BUILDDIR/.cache"
	fi
	chown -R "$BUILDUSER:$BUILDUSER" "$BUILDDIR/"* "$BUILDDIR/.patch" "$BUILDDIR/.ci" "$BUILDDIR/.reuse"

	cd "$BUILDDIR"
	sudo -E -u "$BUILDUSER" "$BUILDDIR/.ci/debian/build.sh"

	mv "$BUILDDIR/.cache" "$ROOTDIR"
	cp "$BUILDDIR/"*.deb "$ROOTDIR"
# otherwise just run normally
else
	"$WORKFLOW_DIR/.ci/debian/build.sh"
fi
