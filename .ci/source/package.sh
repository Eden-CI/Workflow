#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091

ROOTDIR="$PWD"
. "$ROOTDIR"/.ci/common/project.sh
ARTIFACT_NAME="${ROOTDIR}/${PROJECT_PRETTYNAME}-Source-${ARTIFACT_REF}.tar.zst"

cd "${PROJECT_REPO}"

tar --zstd -cf "$ARTIFACT_NAME" ./* .cache .patch

