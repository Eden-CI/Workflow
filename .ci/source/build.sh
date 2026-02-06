#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1091

WORKFLOW_DIR=$(CDPATH='' cd -P -- "$(dirname -- "$0")/../.." && pwd)
. "$WORKFLOW_DIR/.ci/common/project.sh"

cd "${PROJECT_REPO}"

chmod a+x tools/cpm-fetch*.sh
tools/cpm-fetch-all.sh