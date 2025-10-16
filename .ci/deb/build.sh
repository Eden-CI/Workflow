#!/bin/sh -ex

SRC=.ci/deb/PKGBUILD.in
DEST=PKGBUILD

TAG=$(cat GIT-TAG | sed 's/.git//')
if [ -f GIT-RELEASE ]; then
	REF=$(cat GIT-TAG | cut -d'v' -f2)
	PKGVER="$REF"
else
	REF=$(cat GIT-COMMIT)
	PKGVER="$TAG.$REF"
fi

sed "s/%TAG%/$TAG/"       $SRC    > $DEST.1
sed "s/%REF%/$REF/"       $DEST.1 > $DEST.2
sed "s/%PKGVER%/$PKGVER/" $DEST.2 > $DEST.3
sed "s/%PKGVER%/$ARCH/"   $DEST.3 > $DEST

rm $DEST.*

makedeb --printsrcinfo > .SRCINFO
makedeb -s