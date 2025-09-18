#!/bin/sh -ex

mkdir -p artifacts

ARCHES="amd64 steamdeck aarch64"
if [ "$DEVEL" = "false" ]; then
  ARCHES="$ARCHES legacy rog-ally armv9"
fi

for arch in $ARCHES
do
  for compiler in gcc clang; do
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
