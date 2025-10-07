#!/bin/sh -e

# credit: escary and hauntek

ROOTDIR=$PWD
cd build/bin
APP=eden.app

macdeployqt "$APP" -verbose=2
macdeployqt "$APP" -always-overwrite -verbose=2

codesign --deep --force --verbose --sign - "$APP"

mkdir -p $ROOTDIR/artifacts
tar czf $ROOTDIR/artifacts/eden.tar.gz "$APP"
