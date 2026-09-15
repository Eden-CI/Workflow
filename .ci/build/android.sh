#!/bin/sh -e

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

ROOTDIR="$PWD"
ARTIFACTS_DIR="$ROOTDIR/artifacts"
NUM_JOBS=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)
export CMAKE_BUILD_PARALLEL_LEVEL="${NUM_JOBS}"

: "${CCACHE:=false}"
RETURN=0

usage() {
    cat <<EOF
Usage: $0 [-t|--target FLAVOR] [-b|--build-type BUILD_TYPE]
       [-h|--help] [-r|--release] [extra options]

Build script for Android.
Associated variables can be set outside the script,
and will apply both to this script and the packaging script.
bool values are "true" or "false"

Options:
    -r, --release        	Enable update checker. If set, sets the DEVEL bool variable to false.
                         	By default, DEVEL is true.
    -t, --target <FLAVOR> 	Build flavor (variable: FLAVOR)
                          	Valid values are: legacy, optimized, standard, chromeos
                          	Default: standard
    -b, --build-type <TYPE>	Build type (variable: TYPE)
                          	Valid values are: Release, RelWithDebInfo, Debug
                          	Default: Debug

Extra arguments are passed to CMake (e.g. -DCMAKE_OPTION_NAME=VALUE)
Set the CCACHE variable to "true" to enable build caching.
Set PGO_TARGET to "pgo" to make a PGO build (incompatible with ccache)
The APK will be output into "$ARTIFACTS_DIR".

EOF

    exit "$RETURN"
}

die() {
	echo "-- ! $*" >&2
	RETURN=1 usage
}

flavor() {
    [ -z "$1" ] && die "You must specify a valid flavor."

    FLAVOR="$1"
}

type() {
    [ -z "$1" ] && die "You must specify a valid type."

    TYPE="$1"
}

while true; do
	case "$1" in
		-r|--release) DEVEL=false ;;
		-t|--target) flavor "$2"; shift ;;
		-b|--build-type) type "$2"; shift ;;
		-h|--help) usage ;;
		*) break ;;
	esac

	shift
done

: "${FLAVOR:=standard}"
: "${PGO_TARGET:=standard}"
: "${TYPE:=Release}"
: "${DEVEL:=true}"

FLAVOR_LOWER=$(echo "$FLAVOR" | tr '[:upper:]' '[:lower:]')

case "$FLAVOR_LOWER" in
	legacy) APK_FLAVOR=Legacy ;;
	optimized) APK_FLAVOR=GenshinSpoof ;;
	standard) APK_FLAVOR=Mainline ;;
    chromeos) APK_FLAVOR=ChromeOS ;;
	*) die "Invalid build flavor $FLAVOR."
esac

case "$TYPE" in
	RelWithDebInfo|Release|Debug) ;;
	*) die "Invalid build type $TYPE."
esac

if [ -n "${ANDROID_KEYSTORE_B64}" ]; then
    export ANDROID_KEYSTORE_FILE="${ROOTDIR}/ks.jks"
    echo "${ANDROID_KEYSTORE_B64}" | base64 --decode > "${ANDROID_KEYSTORE_FILE}"
	SHA1SUM=$(keytool -list -v -storepass "${ANDROID_KEYSTORE_PASS}" -keystore "${ANDROID_KEYSTORE_FILE}" | grep SHA1 | cut -d " " -f3)
	echo "-- Keystore SHA1 is ${SHA1SUM}"
fi

cd src/android
chmod +x ./gradlew

set -- "$@" -DUSE_CCACHE="${CCACHE}"
[ "$DEVEL" != "true" ] && set -- "$@" -DENABLE_UPDATE_CHECKER=ON
if [ "$BUILD_ID" = "nightly" ]; then
	NIGHTLY=true
else
	NIGHTLY=false
fi

if [ "$PGO_TARGET" = "pgo" ]; then
	echo "Creating PGO build"

	CCACHE=OFF

	PROFDATA="eden.profdata"
	rm -f "$PROFDATA"

	curl -sSfLO "https://$RELEASE_PGO_HOST/$RELEASE_PGO_REPO/releases/latest/download/${PROFDATA}"
	command -v cygpath >/dev/null 2>&1 && PROFDATA="$(cygpath -m "$PROFDATA")"

	PGO_FLAGS="-fprofile-use=$PWD/$PROFDATA -Wno-backend-plugin -Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date"
	set -- "$@" -DCMAKE_C_FLAGS="$PGO_FLAGS" -DCMAKE_CXX_FLAGS="$PGO_FLAGS"
fi

echo "-- building..."

./gradlew "copy${APK_FLAVOR}${TYPE}Outputs" \
    -Dorg.gradle.caching="${CCACHE}" \
    -Dorg.gradle.parallel="${CCACHE}" \
    -Dorg.gradle.workers.max="${NUM_JOBS}" \
    -PYUZU_ANDROID_ARGS="$*" \
	-Pnightly=$NIGHTLY

if [ -n "${ANDROID_KEYSTORE_B64}" ]; then
    rm "${ANDROID_KEYSTORE_FILE}"
fi

cd "$ARTIFACTS_DIR"

name="${PROJECT_PRETTYNAME}-Android-${ARTIFACT_REF}-${FLAVOR_LOWER}"

if [ "$PGO_TARGET" = "pgo" ]; then
	name="$name-pgo"
fi

mv ./*.apk "$name.apk"

cd "$ROOTDIR"

echo "-- Done! APK artifact is in ${ARTIFACTS_DIR}"

ls -l "${ARTIFACTS_DIR}/"
