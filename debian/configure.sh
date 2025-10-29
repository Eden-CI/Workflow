#!/bin/sh -e

if [ -f /etc/os-release ]; then
	. /etc/os-release
else
	echo "Operating system identification not found..."
	exit 1
fi

case "$VERSION_CODENAME" in
	bookworm)
		# Debian 12
		cp debian/control.bookworm debian/control
		;;
	trixie)
		# Debian 13
		cp debian/control.trixie debian/control
		;;
	noble)
		# Ubuntu-24.04
		cp debian/control.noble debian/control
		;;
	*)
		echo "Unknown distro: $NAME $VERSION_ID ($VERSION_CODENAME)"
		exit 1
		;;
esac
