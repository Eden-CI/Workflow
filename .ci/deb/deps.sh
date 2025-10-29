#!/bin/sh -e

# --- Common dependencies ---
depends="libglu1-mesa-dev libhidapi-dev libpulse-dev libudev-dev \
libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 \
libxcb-xinerama0 libxcb-xkb1 libxext-dev libxkbcommon-x11-0 \
mesa-common-dev qt6-base-private-dev libenet-dev libsimpleini-dev \
libcpp-jwt-dev libfmt-dev liblz4-dev libzstd-dev libssl-dev \
libavfilter-dev libavcodec-dev libswscale-dev zlib1g-dev libva-dev \
libvdpau-dev libcpp-httplib-dev libzydis-dev zydis-tools libzycore-dev \
libcubeb-dev libvulkan-dev spirv-tools libusb-1.0-0-dev libsdl2-dev \
libqt6core5compat6 libquazip1-qt6-dev libopus-dev"

# --- Build dependencies ---
makedepends="autoconf glslang-tools cmake git gcc g++ ninja-build qt6-tools-dev \
libtool nasm pkg-config nlohmann-json3-dev spirv-headers build-essential"

# --- Extra dependencies ---
_newbdeps="libfrozen-dev vulkan-utility-libraries-dev libvulkan-memory-allocator-dev"
_newrdeps="libasound2t64 libdiscord-rpc-dev libboost-context-dev libboost-fiber-dev"

MANDB=/var/lib/man-db/auto-update
BUILD_DIR="/tmp/build"

if command -v sudo >/dev/null 2>&1 ; then
    SUDO="sudo"
fi

[ -f "$MANDB" ] && $SUDO rm "$MANDB"

# Install mk-build-deps
if command -v apt >/dev/null 2>&1 ; then
    $SUDO apt update
    $SUDO apt install -y devscripts equivs apt-utils
fi

mkdir -p "$BUILD_DIR"

# Detect variant based on distro and codename
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DIST="$ID"
    VER="$VERSION_CODENAME"
else
    DIST="unknown"
    VER="unknown"
fi

case "$VER" in
    bookworm) VARIANT="bookworm" ;;
    trixie)   VARIANT="trixie" ;;
    *)        VARIANT="noble" ;;
esac

GCC_VER=$(gcc -dumpversion | cut -d. -f1,2)

echo "Detected variant: $VARIANT (GCC $GCC_VER, DIST $DIST $VER)"

# Construct final package lists
final_makedepends="$makedepends"
final_depends="$depends"

case "$VARIANT" in
    noble)
        final_makedepends="$final_makedepends $_newbdeps"
        final_depends="$final_depends $_newrdeps"
        ;;
    trixie)
        final_makedepends="$final_makedepends $_newbdeps"
        final_depends="$final_depends $_newrdeps libmbedtls-dev"
        ;;
    bookworm)
        final_depends="$final_depends libboost-context1.81-dev libboost-fiber1.81-dev"
        ;;
esac

# Install packages
$SUDO apt update
$SUDO apt install -y $final_makedepends $final_depends

