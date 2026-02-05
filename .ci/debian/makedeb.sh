#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

ROOTDIR="$PWD"
BUILDDIR="/build"
BUILDUSER="build"
WORKFLOW_DIR=$(CDPATH='' cd -P -- "$(dirname -- "$0")/../.." && pwd)
ARTIFACTS_DIR="$ROOTDIR/artifacts"

# Use sudo if available, otherwise run directly
if command -v sudo >/dev/null 2>&1 ; then
	SUDO=sudo
fi

if command -v apt >/dev/null 2>&1 ; then
	$SUDO apt update
	$SUDO apt install -y asciidoctor binutils build-essential curl fakeroot file \
		gettext gawk git libarchive-tools lsb-release python3 python3-apt zstd mold
fi

# if in a container (does not have sudo), make a build user and run as that
if ! command -v sudo > /dev/null 2>&1 ; then
	apt install -y sudo

	sudo useradd -m -s /bin/bash -d "$BUILDDIR" "$BUILDUSER"
	echo "$BUILDUSER ALL=NOPASSWD: ALL" >> /etc/sudoers

	# copy workspace stuff to fakeroot
	cp -r "$ROOTDIR/"* "$ROOTDIR/.patch" "$ROOTDIR/.ci" "$ROOTDIR/.reuse" "$BUILDDIR"
	if [ -d "$ROOTDIR/.cache" ]; then
		cp -r "$ROOTDIR/.cache" "$BUILDDIR"
		chown -R "$BUILDUSER:$BUILDUSER" "$BUILDDIR/.cache"
		rm -rf "$ROOTDIR/.cache"
	fi
	chown -R "$BUILDUSER:$BUILDUSER" "$BUILDDIR/"* "$BUILDDIR/.patch" "$BUILDDIR/.ci" "$BUILDDIR/.reuse"

	cd "$BUILDDIR"
	sudo -E -u "$BUILDUSER" "$BUILDDIR/.ci/debian/build.sh"

	# copy back from fakeroot to workspace
	mv "$BUILDDIR/.cache" "$ROOTDIR"
	mkdir -p "$ARTIFACTS_DIR"
	cp "$BUILDDIR/artifacts/"*.deb "$ARTIFACTS_DIR"
# otherwise just run normally
else
	"$WORKFLOW_DIR/.ci/debian/build.sh"
fi
