#!/bin/bash -ex

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1090

FORGEJO_LENV=${FORGEJO_LENV:-"forgejo.env"}

load_payload_env() {
	if [ "$CI" = "true" ]; then
		# Safe export to GITHUB_ENV
		while IFS= read -r line; do
			echo "$line" >> "$GITHUB_ENV"
		done <"$FORGEJO_LENV"
	else
		if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
			echo "This script must be called with 'source' or '.' so the variables are exported to the current shell."
			echo "Example: source ./.ci/common/load-env.sh --load-payload-env"
			exit 1
		fi
	fi
	while IFS= read -r line || [ -n "$line" ]; do
		[[ -z "$line" || "$line" =~ ^# ]] && continue
		echo "$line"
		export "$line"
	done < "$FORGEJO_LENV"
}

case "$1" in
--load-payload-env)
	load_payload_env
	;;
*)
	cat << EOF
Usage: $0 [--load-payload-env]

Commands:
    --load-payload-env: Load the payload environment from forgejo.env.

        Set FORGEJO_LENV to use a custom environment file.
EOF
	;;
esac
