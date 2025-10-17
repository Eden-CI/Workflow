#!/bin/sh -e

MANDB=/var/lib/man-db/auto-update
WORKSPACE="$PWD"

# Use sudo if available, otherwise run directly
if command -v sudo >/dev/null 2>&1 ; then
	SUDO=sudo
fi

[ -f $MANDB ] && $SUDO rm $MANDB

if command -v apt >/dev/null 2>&1 ; then
	$SUDO apt update
	$SUDO apt install -y asciidoctor binutils build-essential curl fakeroot file \
		gettext gawk libarchive-tools lsb-release python3 python3-apt zstd
fi

# if in a container (does not have sudo), make a build user and run as that
if ! command -v sudo > /dev/null 2>&1 ; then
	apt install -y sudo

	useradd -m -s /bin/bash -d /build build
	echo "build ALL=NOPASSWD: ALL" >> /etc/sudoers

	# copy workspace stuff over
	cp -r ./* .patch .ci .reuse /build
	cp -r .cache /build || true

	cd /build
	chown -R build:build ./* .patch .ci .reuse
	chown -R build:build .cache || true
	sudo -E -u build "$PWD/.ci/deb/build.sh"
	mv .cache "$WORKSPACE"
	rm -rf "$WORKSPACE"/.cache
	cp ./*.deb "$WORKSPACE"
# otherwise just run normally
else
	.ci/deb/build.sh
fi