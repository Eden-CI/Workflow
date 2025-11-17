#!/bin/sh -e

# Common project variables

# Acceptable truthy values (any case): 1, true, yes, y, t, on
# Acceptable falsy values: anything else

# names
PROJECT_PRETTYNAME=Eden
PROJECT_REPO=eden

# Is your project desktop only?
DISABLE_ANDROID=OFF

# Does your project need optimized (e.g. PGO, Zen 2, etc) builds?
DISABLE_OPTS=OFF

# Does your project need MinGW builds?
DISABLE_MINGW=OFF

# Does your project need MSVC/arm64 builds?
DISABLE_MSVC_ARM=ON

# Does your project need to explain targets?
EXPLAIN_TARGETS=ON

export PROJECT_PRETTYNAME
export PROJECT_REPO

export DISABLE_ANDROID
export DISABLE_OPTS
export DISABLE_MINGW
export DISABLE_MSVC_ARM

export EXPLAIN_TARGETS