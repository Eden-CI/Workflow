#!/bin/bash -ex

# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

if [ -z "${BASH_VERSION:-}" ]; then
    echo "error: This script MUST be run with bash"
fi

# shellcheck disable=SC1091

ROOTDIR="$PWD"
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$WORKFLOW_DIR/.ci/common/project.sh"
: "${WORKFLOW_JSON:=$ROOTDIR/workflow.json}"

tagged() {
	falsy "$DEVEL"
}

opts() {
	falsy "$DISABLE_OPTS"
}

# FIXME(crueter)
# TODO(crueter): field() func that does linking and such
case "$1" in
master)
	echo "Master branch build for [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF)"
	echo
	echo "Full changelog: [\`$FORGEJO_BEFORE...$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/compare/$FORGEJO_BEFORE...$FORGEJO_REF)"
	;;
pull_request)
	echo "Pull request build #[$FORGEJO_PR_NUMBER]($FORGEJO_PR_URL)"
	echo
	echo "Commit: [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF)"
	echo
	echo "Merge base: [\`$FORGEJO_PR_MERGE_BASE\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_PR_MERGE_BASE)"
	echo "([Master Build]($MASTER_RELEASE_URL?q=$FORGEJO_PR_MERGE_BASE&expanded=true))"
	echo
	echo "## Changelog"
	.ci/common/field.py field="body" default_msg="No changelog provided" pull_request_number="$FORGEJO_PR_NUMBER"
	;;
tag)
	echo "## Changelog"
	;;
nightly)
	echo "Nightly build of commit [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commits/$FORGEJO_LONGSHA)."
	;;
push | test)
	echo "CI test build"
	;;
esac
echo

# TODO(crueter): Don't include fields if their corresponding artifacts aren't found.
link_pkg() {
    local title="$1"
    local pkg="$2"
    echo -n "<a href=\"${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${pkg}\">$title</a>"
}

map_entries() {
    local json="$1"
    local -n out_array=$2
    out_array=()

    while IFS= read -r entry; do
        local link final extra item

        link=$(jq -r '.["package-link"]' <<< "$entry")
        final=$(jq -r '.["package-final"]' <<< "$entry")
        extra=$(jq -r '.["package-extra"] // ""' <<< "$entry")
        item=$(link_pkg "$link" "$final")
        [[ -n "$extra" && tagged && opts ]] && item="$item $(link_pkg "($extra)" "${final}${extra}")"

        out_array+=("$item")
    done < <(jq -c '.' <<< "$json")
}

process_table_id() {
    group="$1"
    ids="$2"
    first="$3"

    # For Collumn 1
    compare="package-title"
    # For Collumn 3
    arm_filter='^(aarch64|arm64)$'
    has_aarch=false

    declare -A title_amd64 title_aarch title_notes title_n
    declare -a all_titles ordered_titles table_lines

    entries=$(jq -c --arg ids "$ids" --arg group "$group" '[.[$group][] | select(.id | test($ids))]' "$WORKFLOW_JSON")
    while IFS= read -r title; do
        all_titles+=("$title")
    done < <(jq -r --arg compare "$compare" '.[] | .[$compare]' <<< "$entries" | sort -u)

    for title in "${all_titles[@]}"; do [[ $title == "$first" ]] && ordered_titles+=("$title"); done
    for title in "${all_titles[@]}"; do [[ $title != "$first" ]] && ordered_titles+=("$title"); done

    for title in "${ordered_titles[@]}"; do
        amd64_lines=()
        aarch_lines=()

        notes=$(jq -r --arg t "$title" --arg compare "$compare" 'first(.[] | select(.[$compare] == $t) | .comments // "")' <<< "$entries")
        entries_amd64=$(jq -c --arg t "$title" --arg compare "$compare" --arg arm_filter "$arm_filter" '.[] | select(.[$compare] == $t and (.target | test($arm_filter) | not))' <<< "$entries")
        entries_aarch64=$(jq -c --arg t "$title" --arg compare "$compare" --arg arm_filter "$arm_filter" '.[] | select(.[$compare] == $t and (.target | test($arm_filter)))' <<< "$entries")

        map_entries "$entries_amd64" amd64_lines
        map_entries "$entries_aarch64" aarch_lines

        n=${#amd64_lines[@]}
        (( ${#aarch_lines[@]} > n )) && n=${#aarch_lines[@]}
        for ((i=0;i<n;i++)); do
            [[ -z "${amd64_lines[i]:-}" ]] && amd64_lines[i]=''
            [[ -z "${aarch_lines[i]:-}" ]] && aarch_lines[i]=''
        done

        title_n["$title"]=$n
        title_amd64["$title"]="$(printf "%s\n" "${amd64_lines[@]}")"
        title_aarch["$title"]="$(printf "%s\n" "${aarch_lines[@]}")"
        title_notes["$title"]="$notes"
    done

    for a in "${title_aarch[@]}"; do [[ -n "$a" ]] && has_aarch=true && break; done

    for title in "${ordered_titles[@]}"; do
        readarray -t amd64_lines <<< "${title_amd64[$title]}"
        readarray -t aarch_lines <<< "${title_aarch[$title]}"

        notes="${title_notes[$title]}"
        n=${title_n[$title]}
        for ((i=0;i<n;i++)); do
            [[ -z "${amd64_lines[i]:-}" && -z "${aarch_lines[i]:-}" ]] && continue
            row="<tr>"
            [[ $i -eq 0 ]] && row+="<td rowspan=\"$n\">$title</td>"
            row+="<td>${amd64_lines[i]:-}</td>"
            if $has_aarch; then
                row+="<td>${aarch_lines[i]:-}</td>"
                [[ $i -eq 0 ]] && row+="<td rowspan=\"$n\">$notes</td>"
            else
                [[ $i -eq 0 ]] && row+="<td colspan=\"2\" rowspan=\"$n\">$notes</td>"
            fi
            row+="</tr>"
            table_lines+=("$row")
        done
    done

    local th_aarch='' th_notes=''
    if $has_aarch; then
        th_aarch='<th width="125">aarch64</th>'
        th_notes='<th width="500">Notes</th>'
    else
        th_notes='<th colspan="2" width="625">Notes</th>'
    fi

    cat << EOF
<table>
<thead align="left">
<tr>
<th width="125">Type</th>
<th width="125">amd64</th>
EOF
    [ -n "$th_aarch" ] && echo "$th_aarch"
    cat << EOF
$th_notes
</tr>
</thead>
<tbody align="left">
EOF
    for row in "${table_lines[@]}"; do
        echo "$row"
    done
    echo "</tbody></table>"
}

android_matrix() {
cat << EOF

## Android

EOF
process_table_id "android" "android" "Standard"
}

linux_matrix() {
cat << EOF

## Linux

### AppImage

Linux packages are distributed via AppImage.
EOF
[[ opts && tagged ]] && cat << EOF
</br><a href="https://zsync.moria.org.uk/">zsync</a> files are provided for easier updating, such as via <a href="https://github.com/ivan-hc/AM">AM</a>.
EOF
process_table_id "linux" "linux" "Standard"
}

deb_matrix() {
cat << EOF

### Debian/Ubuntu

Debian/Ubuntu targets are \`.deb\` files, which can be installed via \`sudo dpkg -i <package>.deb\`.

EOF
process_table_id "linux" "debian" "Ubuntu 24.04"
}

room_matrix() {
cat <<EOF

### Room Executables

These are statically linked Linux executables for the \`eden-room\` binary.

EOF
process_table_id "room" "alpine" "x86_64"
}

win_matrix() {
cat << EOF

## Windows

Windows packages are in-place zip files. Setup files are soon to come.
Note that arm64 builds are experimental.

EOF
process_table_id "windows" "windows|mingw" "MSVC"
}

macos_matrix() {
cat << EOF

## macOS

macOS comes in a tarballed app. These builds are currently experimental, and you should expect major graphical glitches and crashes.</br>
In order to run the app, you *may* need to go to System Settings -> Privacy & Security -> Security -> Allow untrusted app.

EOF
process_table_id "macos" "macos" "macOS"
}

freebsd_matrix() {
cat << EOF

## FreeBSD

EOF
process_table_id "freebsd" "freebsd" "FreeBSD"
}

# MAGIC QLAUNCH HEADER
echo "# Packages"

if truthy "$EXPLAIN_TARGETS"; then
cat << EOF

## Targets

Each build is optimized for a specific architecture and uses a specific compiler.

- **aarch64/arm64**: For devices that use the armv8-a instruction set; e.g. Snapdragon X, all Android devices, and Apple Silicon Macs.</br>
- **amd64**: For devices that use the amd64 (aka x86_64) instruction set; this is exclusively used by Intel and AMD CPUs and is only found on desktops.</br>

**Compilers**

- **MSVC**: The default compiler for Windows. This is the most stable experience, but may lack in performance compared to any of the following alternatives.</br>
- **GCC**: The standard GNU compiler; this is the default for Linux and will provide the most stable experience.</br>
- **PGO**: These are built with Clang, and use PGO. PGO (profile-guided optimization) uses data from prior compilations</br>
to determine the "hotspots" found within the codebase. Using these hotspots,</br>
it can allocate more resources towards these heavily-used areas, and thus generally see improved performance to the tune of ~10-50%,</br>
depending on the specific game, hardware, and platform. Do note that additional instabilities may occur.</br>
EOF
fi

linux_matrix

deb_matrix

room_matrix

win_matrix

android_matrix

macos_matrix

freebsd_matrix

cat << EOF

## Source

Contains all source code, submodules, and CPM cache at the time of release.
This can be extracted with \`tar xf ${PROJECT_PRETTYNAME}-Source-${GITHUB_TAG}.tar.zst\`.

<table>
<thead align="left">
<tr>
<th width="150">File</th>
<th width="700">Description</th>
</tr>
</thead>
<tbody align="left">
<tr>
<td><a href="${GITHUB_DOWNLOAD}/${GITHUB_TAG}/${PROJECT_PRETTYNAME}-Source-${ARTIFACT_REF}.tar.zst">tar.zst</a></td>
<td>Source as a zstd-compressed tarball (Windows: use Git Bash or MSYS2)</td>
</tr>
</tbody>
</table>

EOF
