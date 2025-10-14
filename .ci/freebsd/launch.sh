#!/bin/sh
# Eden Launcher for FreeBSD

DIR=$(dirname "$0")/usr/local

# Setup libs environment
export LD_LIBRARY_PATH="$DIR/lib:$DIR/lib/qt6:$LD_LIBRARY_PATH"
export QT_PLUGIN_PATH="$DIR/lib/qt6/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="$QT_PLUGIN_PATH/platforms"
export QT_TRANSLATIONS_PATH="$DIR/share/translations"

exec "$DIR/bin/eden" "$@"
