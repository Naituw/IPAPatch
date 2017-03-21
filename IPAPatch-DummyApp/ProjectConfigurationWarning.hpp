//
//  ProjectConfigurationWarning.hpp
//  IPAPatch
//
//  Created by wutian on 2017/3/17.
//  Copyright © 2017年 Weibo. All rights reserved.
//

// ⚠️ Note: This is placeholder target for installing the ipa file
//    DO NOT MODIFY.

//    This file is only for warning generation of unconfiguration build settings."

#ifndef ProjectConfigurationWarning_hpp
#define ProjectConfigurationWarning_hpp

#include <stdio.h>
#include <TargetConditionals.h>

// compares two strings in compile time constant fashion
constexpr bool strings_equal(char const * a, char const * b) {
    return *a == *b && (*a == '\0' || strings_equal(a + 1, b + 1));
}

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define TARGET_BUNDLE_ID_STRING STRINGIZE2(TARGET_BUNDLE_ID)

static_assert(!strings_equal(TARGET_BUNDLE_ID_STRING, "com.wutian.example"), "You Should Update  the BundleID in Build Settings before Patching");

// ⚠️ Note: "com.wutian.example" is placeholder bundleID for the result app, you should change it to your own and fixes the signing issues (if any), in the "IPAPatch-DummyApp - Project - General tab"
// ⚠️ Note: The BundleDisplayName of DummyApp will used as prefix of the final name.

#if TARGET_OS_SIMULATOR
#error Simulators is not supported, Please select a real device from Xcode toolbar.
#endif

#endif /* ProjectConfigurationWarning_hpp */
