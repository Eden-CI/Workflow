#!/bin/sh -ex

export ROOTDIR="$PWD"

GITHUB_WORKSPACE="$ROOTDIR"

# install makedeb
echo "-- Installing makedeb..."
[ ! -d makedeb-src ] && git clone 'https://github.com/makedeb/makedeb' makedeb-src
cd makedeb-src
git checkout stable

make prepare VERSION=16.0.0 RELEASE=stable TARGET=apt CURRENT_VERSION=16.0.0 FILESYSTEM_PREFIX="$ROOTDIR/makedeb"
make
make package DESTDIR="$ROOTDIR/makedeb" TARGET=apt

export PATH="$ROOTDIR/makedeb/usr/bin:$PATH"

# now build
echo "-- Building..."
cd "$ROOTDIR"

SRC=.ci/deb/PKGBUILD.in
DEST=PKGBUILD

TAG=$(cat "$GITHUB_WORKSPACE"/GIT-TAG | sed 's/.git//' | sed 's/v//' | sed 's/[-_]/./g' | tr -d '\n')
if [ -f "$GITHUB_WORKSPACE"/GIT-RELEASE ]; then
	REF=$(cat "$GITHUB_WORKSPACE"/GIT-TAG | cut -d'v' -f2)
	PKGVER="$REF"
else
	REF=$(cat "$GITHUB_WORKSPACE"/GIT-COMMIT)
	PKGVER="$TAG.$REF"
fi

sed "s/%TAG%/$TAG/"       $SRC    > $DEST.1
sed "s/%REF%/$REF/"       $DEST.1 > $DEST.2
sed "s/%PKGVER%/$PKGVER/" $DEST.2 > $DEST.3
sed "s/%ARCH%/$ARCH/"     $DEST.3 > $DEST

rm $DEST.*

if ! command -v sudo >/dev/null 2>&1 ; then
	alias sudo="su - root -c"
fi

makedeb --print-srcinfo > .SRCINFO
makedeb -s --no-confirm

# for some grand reason, makepkg does not exit on errors
ls eden*.deb || exit 1
