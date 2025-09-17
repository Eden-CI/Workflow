#!/bin/sh -ex

mkdir -p artifacts

ARCHES="amd64 steamdeck aarch64"
if [ "$DEVEL" = "false" ]; then
  ARCHES="$ARCHES legacy rog-ally armv9"
fi

for arch in $ARCHES
do
  cp linux-$arch/*.AppImage "artifacts/Eden-Linux-${ID}-${arch}.AppImage"
  if [ "$DEVEL" = "false" ]; then
    cp linux-$arch/*.AppImage.zsync "artifacts/Eden-Linux-${ID}-${arch}.AppImage.zsync"
  fi

  cp linux-binary-$arch/*.tar.zst "artifacts/Eden-Linux-${ID}-${binary}.tar.zst"
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
