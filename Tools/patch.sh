#!/bin/sh

#  Copyright (c) 2017-present Wu Tian <wutian@me.com>.

#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:

#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.

#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

#  patch.sh
#  IPAPatch
#
#  Created by wutian on 2017/3/17.


TEMP_PATH="${SRCROOT}/Temp"
ASSETS_PATH="${SRCROOT}/Assets"
TARGET_IPA_PATH="${ASSETS_PATH}/app.ipa"
FRAMEWORKS_TO_INJECT_PATH="${ASSETS_PATH}/Frameworks"

DUMMY_DISPLAY_NAME="" # To be found in Step 0
TARGET_BUNDLE_ID="" # To be found in Step 0
TEMP_APP_PATH=""   # To be found in Step 1
TARGET_APP_PATH="" # To be found in Step 2
TARGET_APP_FRAMEWORKS_PATH="" # To be found in Step 4



# ---------------------------------------------------
# 0. Prepare Working Enviroment

rm -rf "$TEMP_PATH" || true
mkdir -p "$TEMP_PATH" || true

DUMMY_DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "${SRCROOT}/$TARGET_NAME/Info.plist")
echo "DUMMY_DISPLAY_NAME: $DUMMY_DISPLAY_NAME"

TARGET_BUNDLE_ID="$PRODUCT_BUNDLE_IDENTIFIER"
echo "TARGET_BUNDLE_ID: $TARGET_BUNDLE_ID"


# ---------------------------------------------------
# 1. Extract Target IPA

unzip -oqq "$TARGET_IPA_PATH" -d "$TEMP_PATH"
TEMP_APP_PATH=$(set -- "$TEMP_PATH/Payload/"*.app; echo "$1")
echo "TEMP_APP_PATH: $TEMP_APP_PATH"




# ---------------------------------------------------
# 2. Overwrite DummyApp IPA with Target App Contents

TARGET_APP_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app"
echo "TARGET_APP_PATH: $TARGET_APP_PATH"

rm -rf "$TARGET_APP_PATH" || true
mkdir -p "$TARGET_APP_PATH" || true
cp -rf "$TEMP_APP_PATH/" "$TARGET_APP_PATH/"




# ---------------------------------------------------
# 3. Inject the Executable We Wrote and Built (IPAPatch.framework)

APP_BINARY=`plutil -convert xml1 -o - $TARGET_APP_PATH/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`
OPTOOL="${SRCROOT}/Tools/optool"

mkdir "$TARGET_APP_PATH/Dylibs"
cp "$BUILT_PRODUCTS_DIR/IPAPatch.framework/IPAPatch" "$TARGET_APP_PATH/Dylibs/IPAPatch"
for file in `ls -1 "$TARGET_APP_PATH/Dylibs"`; do
    echo -n '     '
    echo "Install Load: $file -> @executable_path/Dylibs/$file"
    "$OPTOOL" install -c load -p "@executable_path/Dylibs/$file" -t "$TARGET_APP_PATH/$APP_BINARY"
done

chmod +x "$TARGET_APP_PATH/$APP_BINARY"




# ---------------------------------------------------
# 4. Inject External Frameworks if Exists

TARGET_APP_FRAMEWORKS_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/Frameworks"

echo "Injecting Frameworks from $FRAMEWORKS_TO_INJECT_PATH"
for file in `ls -1 "${FRAMEWORKS_TO_INJECT_PATH}"`; do
    extension="${file##*.}"
    echo "$file 's extension is $extension"

    if [ "$extension" != "framework" ]
    then
        continue
    fi

    filename="${file%.*}"

    cp "$FRAMEWORKS_TO_INJECT_PATH/$file/$filename" "$TARGET_APP_PATH/Dylibs/$filename"

    echo -n '     '
    echo "Install Load: $file -> @executable_path/Dylibs/$filename"

    echo "TARGET: $TARGET_APP_PATH"

    "$OPTOOL" install -c load -p "@executable_path/Dylibs/$filename" -t "$TARGET_APP_PATH/$APP_BINARY"
done




# ---------------------------------------------------
# 5. Remove Plugins/Watch (AppExtensions), To Simplify the Signing Process

rm -rf "$TARGET_APP_PATH/PlugIns" || true
rm -rf "$TARGET_APP_PATH/Watch" || true




# ---------------------------------------------------
# 7. Update Info.plist for Target App

TARGET_DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$TARGET_APP_PATH/Info.plist")
TARGET_DISPLAY_NAME="$DUMMY_DISPLAY_NAME$TARGET_DISPLAY_NAME"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$TARGET_APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $TARGET_DISPLAY_NAME" "$TARGET_APP_PATH/Info.plist"



# ---------------------------------------------------
# 8. Code Sign All The Things

for DYLIB in "$TARGET_APP_PATH/Dylibs/"*
do
    FILENAME=$(basename $DYLIB)
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$DYLIB"
done

if [ -d "$TARGET_APP_FRAMEWORKS_PATH" ]; then
for FRAMEWORK in "$TARGET_APP_FRAMEWORKS_PATH/"*
do
    FILENAME=$(basename $FRAMEWORK)
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$FRAMEWORK"
done
fi

/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none "$TARGET_APP_PATH/$APP_BINARY"




# ---------------------------------------------------
# 9. Install
#
#    Nothing To Do, Xcode Will Automatically Install the DummyApp We Overwrited



