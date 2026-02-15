#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091

ROOTDIR="$PWD"
DIR=$0; [ -n "${BASH_VERSION-}" ] && DIR="${BASH_SOURCE[0]}"; WORKFLOW_DIR="$(cd "$(dirname -- "$DIR")/../.." && pwd)"
. "$WORKFLOW_DIR/.ci/common/project.sh"

cd "${PROJECT_REPO}"

chmod a+x tools/cpm-fetch*.sh
tools/cpm-fetch-all.sh