#!/bin/sh -e

ROOTDIR="$PWD"

if [ -f /etc/os-release ]; then
	. /etc/os-release
else
	echo "Operating system identification not found..."
	exit 1
fi

case "$VERSION_CODENAME" in
	bookworm|trixie|noble)
		echo "Distro: $NAME $VERSION_ID ($VERSION_CODENAME)"
		;;
	*)
		echo "Unknown distro: $NAME $VERSION_ID ($VERSION_CODENAME)"
		exit 1
		;;
esac

VERSION=$(cat "$ROOTDIR/GIT-TAG" 2>/dev/null || echo 'v0.0.4-rc1')
DEBIAN_VERSION="Standards-Version: $VERSION"
DEBIAN_BUILD="$ROOTDIR/debian/gencontrol/$VERSION_CODENAME/build"
DEBIAN_DEPENDS="$ROOTDIR/debian/gencontrol/$VERSION_CODENAME/depends"

for gencontrol in "$DEBIAN_BUILD" "$DEBIAN_DEPENDS"; do
  [ -f "$gencontrol" ] || { echo "Error: system gencontrol file not found: $gencontrol" >&2; exit 1; }
done

rm -rf "$ROOTDIR/debian/control"
cat "$ROOTDIR/debian/gencontrol/common/head" >> "$ROOTDIR/debian/control"
echo "$DEBIAN_VERSION" >> "$ROOTDIR/debian/control"
cat \
	"$ROOTDIR/debian/gencontrol/common/depends" \
	"$DEBIAN_BUILD" \
	"$ROOTDIR/debian/gencontrol/common/body" \
	"$DEBIAN_DEPENDS" \
	"$ROOTDIR/debian/gencontrol/common/foot" \
	>> "$ROOTDIR/debian/control"
