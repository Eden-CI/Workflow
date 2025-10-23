#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

cd eden

chmod a+x tools/cpm-fetch*.sh
tools/cpm-fetch-all.sh