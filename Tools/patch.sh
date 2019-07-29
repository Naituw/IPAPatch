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
OPTIONS_PATH="${SRCROOT}/Tools/options.plist"
ASSETS_PATH="${SRCROOT}/Assets"
TARGET_IPA_PATH="${ASSETS_PATH}/app.ipa"
FRAMEWORKS_TO_INJECT_PATH="${ASSETS_PATH}/Frameworks"
RESOURCES_TO_INJECT_PATH="${ASSETS_PATH}/Resources"
DYLIBS_TO_INJECT_PATH="${ASSETS_PATH}/Dylibs"

DUMMY_DISPLAY_NAME="" # To be found in Step 0
TARGET_BUNDLE_ID="" # To be found in Step 0
RESTORE_SYMBOLS=false
TEMP_APP_PATH=""   # To be found in Step 1
TARGET_APP_PATH="" # To be found in Step 3
TARGET_APP_FRAMEWORKS_PATH="" # To be found in Step 5


# ---------------------------------------------------
# 0. Prepare Working Enviroment

rm -rf "$TEMP_PATH" || true
mkdir -p "$TEMP_PATH" || true

DUMMY_DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "${SRCROOT}/$TARGET_NAME/Info.plist")
echo "DUMMY_DISPLAY_NAME: $DUMMY_DISPLAY_NAME"

RESTORE_SYMBOLS=$(/usr/libexec/PlistBuddy -c "Print RESTORE_SYMBOLS"  "${OPTIONS_PATH}")
IGNORE_UI_SUPPORTED_DEVICES=$(/usr/libexec/PlistBuddy -c "Print IGNORE_UI_SUPPORTED_DEVICES"  "${OPTIONS_PATH}")

echo "RESTORE_SYMBOLS: $RESTORE_SYMBOLS"
echo "CREATE_IPA_FILE: $CREATE_IPA_FILE"
echo "IGNORE_UI_SUPPORTED_DEVICES: $IGNORE_UI_SUPPORTED_DEVICES"

TARGET_BUNDLE_ID="$PRODUCT_BUNDLE_IDENTIFIER"
echo "TARGET_BUNDLE_ID: $TARGET_BUNDLE_ID"


# ---------------------------------------------------
# 1. Extract Target IPA

unzip -oqq "$TARGET_IPA_PATH" -d "$TEMP_PATH"
TEMP_APP_PATH=$(set -- "$TEMP_PATH/Payload/"*.app; echo "$1")
echo "TEMP_APP_PATH: $TEMP_APP_PATH"




# ---------------------------------------------------
# 2 restore symbol and integrate to Mach-O File

if [ "$RESTORE_SYMBOLS" = true ]; then

    # ---------------------------------------------------
    # 2.1 try to thin Mach-O File

    MACH_O_FILE_NAME=`basename $TEMP_APP_PATH .app`
    MACH_O_FILE_PATH=$TEMP_APP_PATH/$MACH_O_FILE_NAME
    echo "MACH_O_FILE_PATH: $MACH_O_FILE_PATH"

    lipo -thin armv7 $MACH_O_FILE_PATH -o $TEMP_PATH/"$MACH_O_FILE_NAME"_armv7
    lipo -thin arm64 $MACH_O_FILE_PATH -o $TEMP_PATH/"$MACH_O_FILE_NAME"_arm64

    # ---------------------------------------------------
    # 2.2 try to restore symbol by archs

    # Sources: https://github.com/tobefuturer/restore-symbol
    # restore symbol technique

    RESTORE_SYMBOL_TOOL="${SRCROOT}/Tools/restore-symbol"
    "$RESTORE_SYMBOL_TOOL" $TEMP_PATH/$"$MACH_O_FILE_NAME"_armv7 -o $TEMP_PATH/$"$MACH_O_FILE_NAME"_armv7_with_symbol
    "$RESTORE_SYMBOL_TOOL" $TEMP_PATH/$"$MACH_O_FILE_NAME"_arm64 -o $TEMP_PATH/$"$MACH_O_FILE_NAME"_arm64_with_symbol

    # ---------------------------------------------------
    # 2.3 reintegrate Mach-O File

    lipo -create $TEMP_PATH/"$MACH_O_FILE_NAME"_armv7_with_symbol $TEMP_PATH/"$MACH_O_FILE_NAME"_arm64_with_symbol -o $TEMP_PATH/"$MACH_O_FILE_NAME"_with_symbol

    rm -f $MACH_O_FILE_PATH
    cp $TEMP_PATH/"$MACH_O_FILE_NAME"_with_symbol $MACH_O_FILE_PATH

fi # [ "$RESTORE_SYMBOLS" ]


# ---------------------------------------------------
# 3. Overwrite DummyApp IPA with Target App Contents

TARGET_APP_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app"
echo "TARGET_APP_PATH: $TARGET_APP_PATH"

rm -rf "$TARGET_APP_PATH" || true
mkdir -p "$TARGET_APP_PATH" || true
cp -rf "$TEMP_APP_PATH/" "$TARGET_APP_PATH/"




# ---------------------------------------------------
# 4. Inject the Executable We Wrote and Built (IPAPatchFramework.framework)

APP_BINARY=`plutil -convert xml1 -o - $TARGET_APP_PATH/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`
OPTOOL="${SRCROOT}/Tools/optool"

mkdir "$TARGET_APP_PATH/Dylibs"
cp "$BUILT_PRODUCTS_DIR/IPAPatchFramework.framework/IPAPatchFramework" "$TARGET_APP_PATH/Dylibs/IPAPatchFramework"
for file in `ls -1 "$TARGET_APP_PATH/Dylibs"`; do
    echo -n '     '
    echo "Install Load: $file -> @executable_path/Dylibs/$file"
    "$OPTOOL" install -c load -p "@executable_path/Dylibs/$file" -t "$TARGET_APP_PATH/$APP_BINARY"
done

chmod +x "$TARGET_APP_PATH/$APP_BINARY"




# ---------------------------------------------------
# 5. Inject External Files if Exists

CopySwiftStdLib () {
	source_file=$1
	target_dir=$2

	otool -L $source_file | while read -r line ; do
		if [[ $line = "@rpath/libswift"* ]]; then
			re="@rpath\/(libswift[^[:space:]]+.dylib)[[:space:]]";
			if [[ $line =~ $re ]]; then
				LIBNAME=${BASH_REMATCH[1]};
				if ! [ -e "$target_dir/$LIBNAME" ]; then
					LIB_SOURCE_PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphoneos/${LIBNAME}"
					if [ -e $LIB_SOURCE_PATH ]; then
						echo "Copying $LIBNAME: $LIB_SOURCE_PATH"
						cp -rf "$LIB_SOURCE_PATH" "$target_dir"

						# resolve nested dependecies
						CopySwiftStdLib "$target_dir/$LIBNAME" "$target_dir"
					fi
				fi 
			fi
		fi
	done
}

# 5-1. Inject External Frameworks if Exists
TARGET_APP_FRAMEWORKS_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/Frameworks"

echo "Injecting Frameworks from $FRAMEWORKS_TO_INJECT_PATH"
for file in `ls -1 "${FRAMEWORKS_TO_INJECT_PATH}"`; do
    extension="${file##*.}"
    echo "$file 's extension is $extension"

    if [ "$extension" != "framework" ]
    then
        continue
    fi

    mkdir -p "$TARGET_APP_FRAMEWORKS_PATH"
    rsync -av --exclude=".*" "${FRAMEWORKS_TO_INJECT_PATH}/$file" "$TARGET_APP_FRAMEWORKS_PATH"
    filename="${file%.*}"

    echo -n '     '
    echo "Install Load: $file -> @executable_path/Frameworks/$file/$filename"

    "$OPTOOL" install -c load -p "@executable_path/Frameworks/$file/$filename" -t "$TARGET_APP_PATH/$APP_BINARY"

    CopySwiftStdLib "$TARGET_APP_FRAMEWORKS_PATH/$file/$filename" "$TARGET_APP_FRAMEWORKS_PATH"
done

# 5-2. Inject Dylibs if Exists
echo "Injecting Dylibs from $DYLIBS_TO_INJECT_PATH"
for file in `ls -1 "${DYLIBS_TO_INJECT_PATH}"`; do
    if [[ $file = "."* ]]; then
        continue
    fi

    filename="${file%.*}"
   	cp "$DYLIBS_TO_INJECT_PATH/$filename" "$TARGET_APP_PATH/Dylibs/$filename"

    echo -n '     '
	echo "Install Load: $file -> @executable_path/Dylibs/$filename"
	
    "$OPTOOL" install -c load -p "@executable_path/Dylibs/$filename" -t "$TARGET_APP_PATH/$APP_BINARY"

    CopySwiftStdLib "$TARGET_APP_PATH/Dylibs/$filename" "$TARGET_APP_FRAMEWORKS_PATH"
done

# 5-3. Inject External Resources if Exists
echo "Injecting Resources from $RESOURCES_TO_INJECT_PATH"
rsync -av --exclude=".*" "${RESOURCES_TO_INJECT_PATH}/" "$TARGET_APP_PATH"






# ---------------------------------------------------
# 6. Remove Plugins/Watch (AppExtensions), To Simplify the Signing Process

echo "Removing AppExtensions"
rm -rf "$TARGET_APP_PATH/PlugIns" || true
rm -rf "$TARGET_APP_PATH/Watch" || true




# ---------------------------------------------------
# 7. Update Info.plist for Target App

echo "Updating BundleID:$PRODUCT_BUNDLE_IDENTIFIER, DisplayName:$TARGET_DISPLAY_NAME"
TARGET_DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$TARGET_APP_PATH/Info.plist")
TARGET_DISPLAY_NAME="$DUMMY_DISPLAY_NAME$TARGET_DISPLAY_NAME"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$TARGET_APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $TARGET_DISPLAY_NAME" "$TARGET_APP_PATH/Info.plist"

if [ "$IGNORE_UI_SUPPORTED_DEVICES" = true ]; then
    /usr/libexec/PlistBuddy -c "Delete :UISupportedDevices" "$TARGET_APP_PATH/Info.plist"
fi

# ---------------------------------------------------
# 8. Code Sign All The Things

echo "Code Signing Dylibs"
for DYLIB in "$TARGET_APP_PATH/Dylibs/"*
do
    FILENAME=$(basename $DYLIB)
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$DYLIB"
done

echo "Code Signing Frameworks"
if [ -d "$TARGET_APP_FRAMEWORKS_PATH" ]; then
for FRAMEWORK in "$TARGET_APP_FRAMEWORKS_PATH/"*
do
    FILENAME=$(basename $FRAMEWORK)
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$FRAMEWORK"
done
fi

echo "Code Signing App Binary"
/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none "$TARGET_APP_PATH/$APP_BINARY"





# ---------------------------------------------------
# 9. Install
#
#    Nothing To Do, Xcode Will Automatically Install the DummyApp We Overwrited
echo "Done"

