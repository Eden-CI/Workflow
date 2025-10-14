#!/bin/sh -x

mkdir -p artifacts

ARCHES="amd64 steamdeck"

[ "$DISABLE_ARM" != "true" ] && ARCHES="$ARCHES aarch64"
COMPILERS="gcc"
if [ "$DEVEL" = "false" ]; then
  ARCHES="$ARCHES legacy rog-ally"
  [ "$DISABLE_ARM" != "true" ] && ARCHES="$ARCHES armv9"
  COMPILERS="$COMPILERS clang"
fi

for arch in $ARCHES
do
  for compiler in $COMPILERS; do
    ARTIFACT="Eden-Linux-${ID}-${arch}-${compiler}"

    cp linux-$arch-$compiler/*.AppImage "artifacts/$ARTIFACT.AppImage"
    if [ "$DEVEL" = "false" ]; then
      cp linux-$arch-$compiler/*.AppImage.zsync "artifacts/$ARTIFACT.AppImage.zsync"
    fi

    cp linux-binary-$arch-$compiler/*.tar.zst "artifacts/$ARTIFACT.tar.zst"
  done
done

cp android/*.apk artifacts/Eden-Android-${ID}.apk

for arch in amd64 arm64
do
  for compiler in clang msvc; do
    cp windows-$arch-${compiler}/*.zip artifacts/Eden-Windows-${ID}-${arch}-${compiler}.zip
  done
done

if [ -d "source" ]; then
  cp source/source.tar.zst artifacts/Eden-Source-${ID}.tar.zst
fi

cp -r macos/*.tar.gz artifacts/Eden-macOS-${ID}.tar.gz

cp -r freebsd-amd64-clang/*.tar.zst artifacts/Eden-FreeBSD-${ID}-amd64-clang.tar.zst