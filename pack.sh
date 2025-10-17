#!/bin/sh -x

mkdir -p artifacts

ARCHES="amd64 steamdeck"

[ "$DISABLE_ARM" != "true" ] && ARCHES="$ARCHES aarch64"
COMPILERS="gcc clang"
if [ "$DEVEL" = "false" ]; then
	ARCHES="$ARCHES legacy rog-ally"
	[ "$DISABLE_ARM" != "true" ] && ARCHES="$ARCHES armv9"
	# COMPILERS="$COMPILERS clang"
fi

for arch in $ARCHES; do
	for compiler in $COMPILERS; do
		ARTIFACT="Eden-Linux-${ID}-${arch}-${compiler}"

		cp "linux-$arch-$compiler-standard"/*.AppImage "artifacts/$ARTIFACT.AppImage"
		if [ "$DEVEL" = "false" ]; then
			cp "linux-$arch-$compiler-standard"/*.AppImage.zsync "artifacts/$ARTIFACT.AppImage.zsync"
			cp "linux-$arch-$compiler-pgo"/*.AppImage.zsync "artifacts/$ARTIFACT-PGO.AppImage.zsync"
		fi

		# TODO: put this in devel = false
		cp "linux-$arch-$compiler-pgo"/*.AppImage "artifacts/$ARTIFACT-PGO.AppImage"
	done
done

cp android/*.apk "artifacts/Eden-Android-${ID}.apk"

for arch in amd64 arm64; do
	for compiler in clang msvc; do
		cp "windows-$arch-${compiler}"/*.zip "artifacts/Eden-Windows-${ID}-${arch}-${compiler}.zip"
	done
done

if [ -d "source" ]; then
	cp source/source.tar.zst "artifacts/Eden-Source-${ID}.tar.zst"
fi

cp -r macos/*.tar.gz "artifacts/Eden-macOS-${ID}.tar.gz"

# TODO
cp -r freebsd-binary-amd64-clang/*.tar.zst "artifacts/Eden-FreeBSD-${ID}-amd64-clang.tar.zst"

for arch in aarch64 amd64; do
	cp ubuntu-$arch/*.deb "artifacts/Eden-Ubuntu-24.04-${ID}-$arch.deb"

	for ver in 12 13; do
		cp debian-$ver-$arch/*.deb "artifacts/Eden-Debian-$ver-${ID}-$arch.deb"
	done
done
