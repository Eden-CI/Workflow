#!/bin/bash -ex
# The installation script for makedeb. This is the script that's shown and gets ran from https://makedeb.org.

# Handy env vars.
makedeb_url='makedeb.org'
apt_args=()

die_cmd() {
    echo "${1}"
    exit 1
}

answered_yes() {
    if [[ "${1}" == "" || "${1,,}" == "y" ]]; then
        return 0
    else
        return 1
    fi
}

# Pre-checks.
if [[ "${UID}" == "0" ]]; then
    die_cmd "This script is not allowed to be run under the root user. Please run as a normal user and try again."
fi

echo "makedeb installer"

export DEBIAN_FRONTEND=noninteractive
apt_args+=('-y')

echo "Ensuring needed packages are installed..."
if ! sudo apt-get update "${apt_args[@]}"; then
    die_cmd "Failed to update APT cache."
fi

missing_dependencies=()
dpkg-query -W 'wget' > /dev/null 2>&1 || missing_dependencies+=('wget')
dpkg-query -W 'gpg' > /dev/null 2>&1 || missing_dependencies+=('gpg')

if ! ( test -z "${missing_dependencies[*]}" || sudo apt-get install "${apt_args[@]}" --mark-auto "${missing_dependencies[@]}" ); then
    die_cmd "Failed to install needed packages."
fi

echo

echo "Setting up makedeb APT repository..."
if ! wget -qO - "https://proget.${makedeb_url}/debian-feeds/makedeb.pub" | gpg --dearmor | sudo tee /usr/share/keyrings/makedeb-archive-keyring.gpg 1> /dev/null; then
    die_cmd "Failed to set up makedeb APT repository."
fi
echo "deb [signed-by=/usr/share/keyrings/makedeb-archive-keyring.gpg arch=all] https://proget.${makedeb_url} makedeb main" | sudo tee /etc/apt/sources.list.d/makedeb.list 1> /dev/null

echo "Updating APT cache..."
if ! sudo apt-get update "${apt_args[@]}"; then
    die_cmd "Failed to update APT cache."
fi

echo
echo "Installing..."
if ! sudo apt-get install "${apt_args[@]}" -- makedeb; then
    die_cmd "Failed to install package."
fi

echo "Enjoy makedeb!"

# vim: set sw=4 expandtab:
