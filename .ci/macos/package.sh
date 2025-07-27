#!/bin/sh

# credit: escary and hauntek

cd build
APP=./bin/eden.app

macdeployqt "$APP"
macdeployqt "$APP" -always-overwrite

# FixMachOLibraryPaths
find "$APP/Contents/Frameworks" ""$APP/Contents/MacOS"" -type f \( -name "*.dylib" -o -perm +111 \) | while read file; do
    if file "$file" | grep -q "Mach-O"; then
        otool -L "$file" | awk '/@rpath\// {print $1}' | while read lib; do
            lib_name="${lib##*/}"
            new_path="@executable_path/../Frameworks/$lib_name"
            install_name_tool -change "$lib" "$new_path" "$file"
        done

        if [[ "$file" == *.dylib ]]; then
            lib_name="${file##*/}"
            new_id="@executable_path/../Frameworks/$lib_name"
            install_name_tool -id "$new_id" "$file"
        fi
    fi
done
codesign --deep --force --verify --verbose --sign - "$APP"

ZIP_NAME="eden-macos.zip"
mkdir -p artifacts

mv $APP .
7z a -tzip "$ZIP_NAME" eden.app
mv "$ZIP_NAME" artifacts/
mv artifacts ../../