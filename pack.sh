#!/bin/sh -ex

mkdir -p artifacts

ARCHES="amd64 aarch64 steamdeck"
if [ "$DEVEL" = "false" ]; then
  ARCHES="$ARCHES legacy rog-ally armv9"
fi

for arch in $ARCHES
do
  cp linux-$arch/*.AppImage "artifacts/Eden-Linux-${ID}-${arch}.AppImage"
  if [ "$DEVEL" = "false" ]; then
    cp linux-$arch/*.AppImage.zsync "artifacts/Eden-Linux-${ID}-${arch}.AppImage.zsync"
  fi
done

cp android/*.apk artifacts/Eden-Android-${ID}.apk

for arch in amd64 # arm64
do
  cp windows-$arch/*.zip artifacts/Eden-Windows-${ID}-${arch}.zip
done

if [ -d "source" ]; then
  for ext in zip tar.zst
  do
    cp source/source.$ext artifacts/Eden-Source-${ID}.$ext
  done
fi

cp -r macos/*.zip artifacts/Eden-macOS-${ID}.zip