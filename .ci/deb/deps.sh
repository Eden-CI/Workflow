#!/bin/bash

.ci/deb/install.sh

makedeb --help || { echo 'makedeb failed to install' ; exit 1; }