#!/bin/sh -e

MANDB=/var/lib/man-db/auto-update
export ROOTDIR="$PWD"

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
	useradd -m -s /bin/bash -d /build build
	echo "build ALL=NOPASSWD: ALL" >> /etc/sudoers

	# copy workspace stuff over
	cp -r ./* .cache .patch .ci .reuse /build
	chown -R build:build /build

	su - build -c sh -c "$PWD/.ci/deb/build.sh"
	cp /build/*.deb .
# otherwise just run normally
else
	.ci/deb/build.sh
fi