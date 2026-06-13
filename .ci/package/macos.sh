#!/bin/sh -e

ROOTDIR="$PWD"

# shellcheck disable=SC1091
. "$ROOTDIR/.ci/build/project.sh"

BUILDDIR="${BUILDDIR:-$ROOTDIR/build}"
ARTIFACTS_DIR="$ROOTDIR/artifacts"
APP="${PROJECT_REPO}.app"
APPDIR="${BUILDDIR}/bin"

FORMAT="${FORMAT:-dmg}"

usage() {
    cat <<-EOF
		Usage: $0 [--format dmg|tar]

		Packages the macOS build into a .dmg (default) or .tar.gz archive.
	EOF
    exit 0
}

while true; do
    case "$1" in
        --format) FORMAT="$2"; shift ;;
        -h|--help) usage ;;
        *) break ;;
    esac
    shift
done

codesign --deep --force --verbose --sign - "$APPDIR/$APP"
rm -rf "$APPDIR"/send-presence.app
mkdir -p "$ARTIFACTS_DIR"

artifact_base="${ARTIFACTS_DIR}/${PROJECT_PRETTYNAME}-macOS-${ARTIFACT_REF}"

case "$FORMAT" in
    dmg)
        ARTIFACT="$artifact_base.dmg"
        VOLUME_NAME="${PROJECT_PRETTYNAME} ${ARTIFACT_REF} Installer"

		# TODO: backdrop
        sudo create-dmg \
          --volname "${VOLUME_NAME}" \
          --window-pos 200 120 \
          --window-size 800 400 \
          --icon-size 128 \
          --icon "${APP}" 200 190 \
          --hide-extension "${APP}" \
          --app-drop-link 600 185 \
          "${ARTIFACT}" \
          "${APPDIR}"
        ;;
    tar)
        ARTIFACT="$artifact_base.tar.gz"

        cd "$APPDIR"
        tar czf "$ARTIFACT" "$APP"
        cd "$ROOTDIR"
        ;;
    *)
        echo "Unknown format: $FORMAT. Valid options: dmg, tar" >&2
        exit 1
        ;;
esac

echo "-- macOS package created at $ARTIFACT"
