#!/bin/bash -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

if [ -n "${ANDROID_KEYSTORE_B64}" ]; then
    export ANDROID_KEYSTORE_FILE="${GITHUB_WORKSPACE}/ks.jks"
    echo "${ANDROID_KEYSTORE_B64}" | base64 --decode > "${ANDROID_KEYSTORE_FILE}"
else
    echo "CI builds without a valid keystore provided are not supported."
    if [ "${CI_PR_FORK}" != "true" ]; then
        exit 1
    fi
fi

ROOTDIR="$PWD"

SHA1SUM=$(keytool -list -v -storepass "${ANDROID_KEYSTORE_PASS}" -keystore "${ANDROID_KEYSTORE_FILE}" | grep SHA1 | cut -d " " -f3)
echo "Keystore SHA1 is ${SHA1SUM}"

chmod +x ./gradlew

CCACHE="${CCACHE:-false}"
NUM_JOBS=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)
export CMAKE_BUILD_PARALLEL_LEVEL="${NUM_JOBS}"

EXTRA_ARGS=("$@")
ANDROID_CMAKE_ARGS=("-DUSE_CCACHE=${CCACHE}" "${EXTRA_ARGS[@]}")
[ "$DEVEL" != "true" ] && ANDROID_CMAKE_ARGS+=(-DENABLE_UPDATE_CHECKER=ON)
echo "Android CMake flags: ${ANDROID_CMAKE_ARGS[*]}"

case "$TARGET" in
	legacy) FLAVOR=Legacy ;;
	optimized) FLAVOR=GenshinSpoof ;;
	standard|*) FLAVOR=Mainline ;;
esac

echo "-- building APK"
./gradlew assemble${FLAVOR}Release \
    -Dorg.gradle.caching="${CCACHE}" \
    -Dorg.gradle.parallel="${CCACHE}" \
    -Dorg.gradle.workers.max="${NUM_JOBS}" \
    -PYUZU_ANDROID_ARGS="${ANDROID_CMAKE_ARGS[*]}"

echo "-- bundling AAB"
./gradlew bundle${FLAVOR}Release \
    -Dorg.gradle.caching="${CCACHE}" \
    -Dorg.gradle.workers.max="${NUM_JOBS}" \
    -Dorg.gradle.parallel="${CCACHE}" \
    -PYUZU_ANDROID_ARGS="${ANDROID_CMAKE_ARGS[*]}"

if [ -n "${ANDROID_KEYSTORE_B64}" ]; then
    rm -f "${ANDROID_KEYSTORE_FILE}"
fi
