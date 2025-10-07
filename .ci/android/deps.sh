#!/bin/sh -e

# Explicitly disable man-db auto update (takes forever lol)
sudo rm /var/lib/man-db/auto-update

sudo apt-get update -y
sudo apt-get install apksigner glslang-tools libvulkan-dev python3-requests -y