#!/bin/sh

#  create_ipa.sh
#  IPAPatch
#
#  Created by 吴天 on 2017/8/26.
#  Copyright © 2017年 Weibo. All rights reserved.

OPTIONS_PATH="${SRCROOT}/Tools/options.plist"
TARGET_APP_PATH="$BUILT_PRODUCTS_DIR/IPAPatch-DummyApp.app"
TARGET_DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$TARGET_APP_PATH/Info.plist")

CREATE_IPA_FILE=$(/usr/libexec/PlistBuddy -c "Print CREATE_IPA_FILE"  "${OPTIONS_PATH}")

if [ "$CREATE_IPA_FILE" = true ]; then

    IPA_PRODUCT_PATH="${SRCROOT}/Product"
    IPA_PRODUCT_PAYLOAD_PATH="${IPA_PRODUCT_PATH}/Payload"

    rm -rf "${IPA_PRODUCT_PATH}" || true

    mkdir -p "${IPA_PRODUCT_PATH}"
    mkdir -p "${IPA_PRODUCT_PAYLOAD_PATH}"

    cp -rf "$TARGET_APP_PATH" "$IPA_PRODUCT_PAYLOAD_PATH"

    cd "$IPA_PRODUCT_PATH"

    zip -qr "${TARGET_DISPLAY_NAME}.ipa" "Payload/"

    rm -rf "$IPA_PRODUCT_PAYLOAD_PATH"

fi
