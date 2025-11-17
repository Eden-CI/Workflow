#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091

ROOTDIR="$PWD"
. "$ROOTDIR"/ci/common/project.sh

cd "${PROJECT_REPO}"

chmod a+x tools/cpm-fetch*.sh
tools/cpm-fetch-all.sh