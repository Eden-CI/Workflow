#!/bin/bash -e

# SPDX-FileCopyrightText: 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

if [ ! -z "${ANDROID_KEYSTORE_B64}" ]; then
    export ANDROID_KEYSTORE_FILE="${GITHUB_WORKSPACE}/ks.jks"
    base64 --decode <<< "${ANDROID_KEYSTORE_B64}" > "${ANDROID_KEYSTORE_FILE}"
else
    echo "CI builds without a valid keystore provided are not supported."
    exit 1
fi

SHA1SUM=$(keytool -list -v -storepass ${ANDROID_KEYSTORE_PASS} -keystore ${ANDROID_KEYSTORE_FILE} | grep SHA1 | cut -d " " -f3)
echo "Keystore SHA1 is ${SHA1SUM}"

cd src/android
chmod +x ./gradlew

./gradlew assembleMainlineRelease \
    -Dorg.gradle.caching=${CCACHE:-false} \
    -Dorg.gradle.parallel=${CCACHE:-false} \
    -PYUZU_ANDROID_ARGS="-DUSE_CCACHE=${CCACHE:-false} $@"

./gradlew bundleMainlineRelease \
    -Dorg.gradle.caching=${CCACHE:-false} \
    -Dorg.gradle.parallel=${CCACHE:-false} \
    -PYUZU_ANDROID_ARGS="-DUSE_CCACHE=${CCACHE:-false} $@"

if [ ! -z "${ANDROID_KEYSTORE_B64}" ]; then
    rm "${ANDROID_KEYSTORE_FILE}"
fi
