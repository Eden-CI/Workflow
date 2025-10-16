#!/bin/sh -e

export TERM=dumb

set -x
bash -c "$(wget -qO - 'https://shlink.makedeb.org/install')"