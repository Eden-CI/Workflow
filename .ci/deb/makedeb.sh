#!/bin/sh -e

MANDB=/var/lib/man-db/auto-update
export ROOTDIR="$PWD"

[ -f $MANDB ] && sudo rm $MANDB

if command -v apt >/dev/null 2>&1 ; then
    # Use sudo if available, otherwise run directly
    if command -v sudo >/dev/null 2>&1 ; then
		SUDO=sudo
    fi
fi

$SUDO apt update
$SUDO apt install -y asciidoctor binutils build-essential curl fakeroot file \
	gettext gawk libarchive-tools lsb-release python3 python3-apt zstd

# if in a container (does not have sudo), install sudo and make a build user
if ! command -v sudo > /dev/null 2>&1 ; then
	useradd -m -s /bin/bash -d /build build
	echo "build ALL=NOPASSWD: ALL" >> /etc/sudoers
	su - build -c sh -c "$PWD/.ci/deb/build.sh"
# otherwise just run normally
else
	.ci/deb/build.sh
fi