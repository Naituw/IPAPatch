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

PLATFORM="$1"

TEMP_PATH="${SRCROOT}/Temp"
OPTIONS_PATH="${SRCROOT}/Tools/options.plist"
ASSETS_PATH="${SRCROOT}/Assets"
TARGET_IPA_PATH="${ASSETS_PATH}/app.ipa"
TARGET_MAC_APP_PATH="${ASSETS_PATH}/macapp.app"
FRAMEWORKS_TO_INJECT_PATH="${ASSETS_PATH}/Frameworks"
RESOURCES_TO_INJECT_PATH="${ASSETS_PATH}/Resources"
DYLIBS_TO_INJECT_PATH="${ASSETS_PATH}/Dylibs"

DUMMY_DISPLAY_NAME="" # To be found in Step 0
TARGET_BUNDLE_ID="" # To be found in Step 0
RESTORE_SYMBOLS=false
REMOVE_WATCHPLACEHOLDER=false
USE_ORIGINAL_ENTITLEMENTS=false
TEMP_APP_PATH=""   # To be found in Step 1
TARGET_APP_PATH="" # To be found in Step 3
TARGET_APP_CONTENTS_PATH="" # To be found in Step 3
TARGET_APP_FRAMEWORKS_PATH="" # To be found in Step 5
TARGET_APP_FRAMEWORKS_SUBPATH="" # To be found in Step 5

# ---------------------------------------------------
# 0. Prepare Working Enviroment

rm -rf "$TEMP_PATH" || true
mkdir -p "$TEMP_PATH" || true

DUMMY_DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "${SRCROOT}/$TARGET_NAME/Info.plist")
echo "DUMMY_DISPLAY_NAME: $DUMMY_DISPLAY_NAME"

RESTORE_SYMBOLS=$(/usr/libexec/PlistBuddy -c "Print RESTORE_SYMBOLS"  "${OPTIONS_PATH}")
IGNORE_UI_SUPPORTED_DEVICES=$(/usr/libexec/PlistBuddy -c "Print IGNORE_UI_SUPPORTED_DEVICES"  "${OPTIONS_PATH}")
REMOVE_WATCHPLACEHOLDER=$(/usr/libexec/PlistBuddy -c "Print REMOVE_WATCHPLACEHOLDER"  "${OPTIONS_PATH}")
USE_ORIGINAL_ENTITLEMENTS=$(/usr/libexec/PlistBuddy -c "Print USE_ORIGINAL_ENTITLEMENTS"  "${OPTIONS_PATH}")

echo "RESTORE_SYMBOLS: $RESTORE_SYMBOLS"
echo "CREATE_IPA_FILE: $CREATE_IPA_FILE"
echo "IGNORE_UI_SUPPORTED_DEVICES: $IGNORE_UI_SUPPORTED_DEVICES"

TARGET_BUNDLE_ID="$PRODUCT_BUNDLE_IDENTIFIER"
echo "TARGET_BUNDLE_ID: $TARGET_BUNDLE_ID"


# ---------------------------------------------------
# 1. Extract Target IPA

if [ $PLATFORM = "Mac" ]
then
    echo "Copying Mac App to Temp folder"
    cp -rP "$TARGET_MAC_APP_PATH" "$TEMP_PATH"
    TEMP_APP_PATH=$(set -- "$TEMP_PATH/"*.app; echo "$1")
else
    echo "Extracting iOS App to Temp folder"
    unzip -oqq "$TARGET_IPA_PATH" -d "$TEMP_PATH"
    TEMP_APP_PATH=$(set -- "$TEMP_PATH/Payload/"*.app; echo "$1")
fi
    
echo "TEMP_APP_PATH: $TEMP_APP_PATH"

# ---------------------------------------------------
# 2 restore symbol and integrate to Mach-O File

if [ "$RESTORE_SYMBOLS" = true ]; then

    # ---------------------------------------------------
    # 2.1 try to thin Mach-O File

    MACH_O_FILE_NAME=`basename $TEMP_APP_PATH .app`
    MACH_O_FILE_PATH=$TEMP_APP_PATH/$MACH_O_FILE_NAME
    echo "MACH_O_FILE_PATH: $MACH_O_FILE_PATH"

    ARCHS=`lipo -archs $MACH_O_FILE_PATH`
    ARCH_COUNT=${#ARCHS[@]}
    
    if [ $ARCH_COUNT -eq 1 ]; then
        echo "skipping lipo -thin: non-fat binary"
    else
        lipo -thin armv7 $MACH_O_FILE_PATH -o $TEMP_PATH/"$MACH_O_FILE_NAME"_armv7
        lipo -thin arm64 $MACH_O_FILE_PATH -o $TEMP_PATH/"$MACH_O_FILE_NAME"_arm64
    fi

    # ---------------------------------------------------
    # 2.2 try to restore symbol by archs

    # Sources: https://github.com/tobefuturer/restore-symbol
    # restore symbol technique

    RESTORE_SYMBOL_TOOL="${SRCROOT}/Tools/restore-symbol"
    
    if [ $ARCH_COUNT -eq 1 ]; then
        "$RESTORE_SYMBOL_TOOL" $MACH_O_FILE_PATH -o $TEMP_PATH/$"$MACH_O_FILE_NAME"_with_symbol
    else
        "$RESTORE_SYMBOL_TOOL" $TEMP_PATH/$"$MACH_O_FILE_NAME"_armv7 -o $TEMP_PATH/$"$MACH_O_FILE_NAME"_armv7_with_symbol
        "$RESTORE_SYMBOL_TOOL" $TEMP_PATH/$"$MACH_O_FILE_NAME"_arm64 -o $TEMP_PATH/$"$MACH_O_FILE_NAME"_arm64_with_symbol
    fi

    # ---------------------------------------------------
    # 2.3 reintegrate Mach-O File

    if [ $ARCH_COUNT -eq 1 ]; then
        echo "skipping lipo -create: non-fat binary"
    else
        lipo -create $TEMP_PATH/"$MACH_O_FILE_NAME"_armv7_with_symbol $TEMP_PATH/"$MACH_O_FILE_NAME"_arm64_with_symbol -o $TEMP_PATH/"$MACH_O_FILE_NAME"_with_symbol
    fi

    rm -f $MACH_O_FILE_PATH
    cp $TEMP_PATH/"$MACH_O_FILE_NAME"_with_symbol $MACH_O_FILE_PATH

fi # [ "$RESTORE_SYMBOLS" ]


# ---------------------------------------------------
# 3. Overwrite DummyApp IPA with Target App Contents

TARGET_APP_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app"
if [ $PLATFORM = "Mac" ]
then
    TARGET_APP_CONTENTS_PATH="$TARGET_APP_PATH/Contents"
else
    TARGET_APP_CONTENTS_PATH="$TARGET_APP_PATH"
fi
echo "TARGET_APP_PATH: $TARGET_APP_PATH"

rm -rf "$TARGET_APP_PATH" || true
mkdir -p "$TARGET_APP_PATH" || true
cp -rfP "$TEMP_APP_PATH/" "$TARGET_APP_PATH/"




# ---------------------------------------------------
# 4. Inject the Executable We Wrote and Built (IPAPatchFramework.framework)

APP_BINARY=`plutil -convert xml1 -o - $TARGET_APP_CONTENTS_PATH/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`
if [ $PLATFORM = "Mac" ]
then
    APP_BINARY="MacOS/$APP_BINARY"
fi
OPTOOL="${SRCROOT}/Tools/optool"

mkdir "$TARGET_APP_CONTENTS_PATH/Dylibs"
if [ $PLATFORM = "Mac" ]
then
    cp "$BUILT_PRODUCTS_DIR/IPAPatchFrameworkMac.framework/IPAPatchFrameworkMac" "$TARGET_APP_CONTENTS_PATH/Dylibs/IPAPatchFramework"
else
    cp "$BUILT_PRODUCTS_DIR/IPAPatchFramework.framework/IPAPatchFramework" "$TARGET_APP_CONTENTS_PATH/Dylibs/IPAPatchFramework"
fi
for file in `ls -1 "$TARGET_APP_CONTENTS_PATH/Dylibs"`; do
    echo -n '     '
    
    if [ $PLATFORM = "Mac" ]
    then
        FRAMEWORK_LOAD_PATH="@executable_path/../Dylibs/$file"
    else
        FRAMEWORK_LOAD_PATH="@executable_path/Dylibs/$file"
    fi
    
    echo "Install Load: $file -> $FRAMEWORK_LOAD_PATH"
    "$OPTOOL" install -c load -p "$FRAMEWORK_LOAD_PATH" -t "$TARGET_APP_CONTENTS_PATH/$APP_BINARY"
done

chmod +x "$TARGET_APP_CONTENTS_PATH/$APP_BINARY"




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
TARGET_APP_FRAMEWORKS_PATH="$TARGET_APP_CONTENTS_PATH/Frameworks"

echo "Injecting Frameworks from $FRAMEWORKS_TO_INJECT_PATH"
for file in `ls -1 "${FRAMEWORKS_TO_INJECT_PATH}"`; do
    extension="${file##*.}"
    echo "$file 's extension is $extension"
    
    filename="${file%.*}"
    TARGET_APP_FRAMEWORKS_SUBPATH="$file/$filename"
    
    if [ "$extension" != "framework" ]
    then
        #continue
        echo "Maybe ""$file"" is not a framework"
        TARGET_APP_FRAMEWORKS_SUBPATH="$file"
    fi

    mkdir -p "$TARGET_APP_FRAMEWORKS_PATH"
    rsync -av --exclude=".*" "${FRAMEWORKS_TO_INJECT_PATH}/$file" "$TARGET_APP_FRAMEWORKS_PATH"

    echo -n '     '
    echo "Install Load: $file -> @executable_path/Frameworks/$TARGET_APP_FRAMEWORKS_SUBPATH"

    "$OPTOOL" install -c load -p "@executable_path/Frameworks/$TARGET_APP_FRAMEWORKS_SUBPATH" -t "$TARGET_APP_CONTENTS_PATH/$APP_BINARY"

    CopySwiftStdLib "$TARGET_APP_FRAMEWORKS_PATH/$TARGET_APP_FRAMEWORKS_SUBPATH" "$TARGET_APP_FRAMEWORKS_PATH"
done

# 5-2. Inject Dylibs if Exists
echo "Injecting Dylibs from $DYLIBS_TO_INJECT_PATH"
for file in `ls -1 "${DYLIBS_TO_INJECT_PATH}"`; do
    if [[ $file = "."* ]]; then
        continue
    fi

    filename="${file%.*}"
   	cp "$DYLIBS_TO_INJECT_PATH/$filename" "$TARGET_APP_CONTENTS_PATH/Dylibs/$filename"

    echo -n '     '
	echo "Install Load: $file -> @executable_path/Dylibs/$filename"
	
    "$OPTOOL" install -c load -p "@executable_path/Dylibs/$filename" -t "$TARGET_APP_CONTENTS_PATH/$APP_BINARY"

    CopySwiftStdLib "$TARGET_APP_CONTENTS_PATH/Dylibs/$filename" "$TARGET_APP_FRAMEWORKS_PATH"
done

# 5-3. Inject External Resources if Exists
echo "Injecting Resources from $RESOURCES_TO_INJECT_PATH"
rsync -av --exclude=".*" "${RESOURCES_TO_INJECT_PATH}/" "$TARGET_APP_CONTENTS_PATH"






# ---------------------------------------------------
# 6. Remove Plugins/Watch (AppExtensions), To Simplify the Signing Process

echo "Removing AppExtensions"
rm -rf "$TARGET_APP_CONTENTS_PATH/PlugIns" || true
rm -rf "$TARGET_APP_CONTENTS_PATH/Watch" || true

if [ "$REMOVE_WATCHPLACEHOLDER" = true ]; then
    echo "Removing com.apple.WatchPlaceholder"
    rm -rf "$TARGET_APP_CONTENTS_PATH/com.apple.WatchPlaceholder" || true
fi


# ---------------------------------------------------
# 7. Update Info.plist for Target App

echo "Updating BundleID:$PRODUCT_BUNDLE_IDENTIFIER, DisplayName:$TARGET_DISPLAY_NAME"
TARGET_DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$TARGET_APP_CONTENTS_PATH/Info.plist")
TARGET_DISPLAY_NAME="$DUMMY_DISPLAY_NAME$TARGET_DISPLAY_NAME"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$TARGET_APP_CONTENTS_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $TARGET_DISPLAY_NAME" "$TARGET_APP_CONTENTS_PATH/Info.plist"

if [ "$IGNORE_UI_SUPPORTED_DEVICES" = true ]; then
    /usr/libexec/PlistBuddy -c "Delete :UISupportedDevices" "$TARGET_APP_CONTENTS_PATH/Info.plist"
fi

# ---------------------------------------------------
# 8. Code Sign All The Things

if [ "$USE_ORIGINAL_ENTITLEMENTS" = true ]; then
ENTITLEMENTS="$TEMP_PATH/entitlements.xcent"
codesign -d --entitlements :- "$TARGET_APP_PATH" > "$ENTITLEMENTS"
fi

echo "Code Signing Dylibs"
if [ "$USE_ORIGINAL_ENTITLEMENTS" = true ]; then
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --entitlements "$ENTITLEMENTS" "$TARGET_APP_CONTENTS_PATH/Dylibs/"*
else
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$TARGET_APP_CONTENTS_PATH/Dylibs/"*
fi


echo "Code Signing Frameworks"
if [ -d "$TARGET_APP_FRAMEWORKS_PATH" ]; then
    if [ "$USE_ORIGINAL_ENTITLEMENTS" = true ]; then
        echo "/usr/bin/codesign --force --sign $EXPANDED_CODE_SIGN_IDENTITY --entitlements $ENTITLEMENTS $TARGET_APP_FRAMEWORKS_PATH/*"
        /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --entitlements "$ENTITLEMENTS" "$TARGET_APP_FRAMEWORKS_PATH/"*
    else
        echo "/usr/bin/codesign --force --sign $EXPANDED_CODE_SIGN_IDENTITY $TARGET_APP_FRAMEWORKS_PATH/*"
        /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$TARGET_APP_FRAMEWORKS_PATH/"*
    fi
fi

echo "Code Signing App Binary"
if [ "$USE_ORIGINAL_ENTITLEMENTS" = true ]; then
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none --entitlements "$ENTITLEMENTS" "$TARGET_APP_PATH"
    if [ $PLATFORM = "Mac" ]
    then
        /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none --entitlements "$ENTITLEMENTS" "$TARGET_APP_CONTENTS_PATH/MacOS/"*
    fi
else
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none "$TARGET_APP_PATH"
    if [ $PLATFORM = "Mac" ]
    then
        /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none "$TARGET_APP_CONTENTS_PATH/MacOS/"*
    fi
fi





# ---------------------------------------------------
# 9. Install
#
#    Nothing To Do, Xcode Will Automatically Install the DummyApp We Overwrited
echo "Done"

