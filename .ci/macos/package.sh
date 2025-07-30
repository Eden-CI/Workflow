#!/bin/sh

# credit: escary and hauntek

cd eden/build
APP=./bin/eden.app

macdeployqt "$APP" -verbose=2
macdeployqt "$APP" -always-overwrite -verbose=2

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

codesign --deep --force --verbose --sign - "$APP"

mkdir -p artifacts
tar czf artifacts/eden.tar.zst "$APP"
mv artifacts ../../