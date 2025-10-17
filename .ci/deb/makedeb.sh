#!/bin/sh -e

# if in a container (does not have sudo), install sudo and make a build user
if command -v sudo > /dev/null ; then
	useradd -m -s /bin/bash -d /build build
	echo "build ALL=NOPASSWD: ALL" >> /etc/sudoers
	apt install sudo
	exec su - build -c ".ci/deb/build.sh"
# otherwise just run normally
else
	.ci/deb/build.sh
fi