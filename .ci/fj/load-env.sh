#!/bin/sh -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

FORGEJO_LENV=${FORGEJO_LENV:-"forgejo.env"}

if [ ! -f "$FORGEJO_LENV" ]; then
    echo "error: environment file '$FORGEJO_LENV' not found."
    exit 1
fi

if [ "$CI" = "true" ]; then
    # Safe export to GITHUB_ENV
    while IFS= read -r line; do
        echo "$line" >> "$GITHUB_ENV"
    done <"$FORGEJO_LENV"
else
    if [ "$(basename -- "$0")" = "load-env.sh" ]; then
        echo "This script must be called with 'source' or '.' so the variables are exported to the current shell."
        echo "Example: . .ci/fj/load-env.sh"
        exit 1
    fi
fi

while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        (""|\#*) continue ;;
    esac

    echo "$line"
    # shellcheck disable=SC2163
    export "$line"
done < "$FORGEJO_LENV"
