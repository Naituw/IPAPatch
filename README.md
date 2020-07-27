![IPAPatch Logo](http://wx1.sinaimg.cn/large/bebedbb5ly1fdrgg0v1hjj20e205qdgi.jpg)

IPAPatch provide a simple way to patch iOS Apps, without needing to jailbreak.

[ [Features](#features) &bull; [Instructions](#instructions) &bull; [Example](#example) &bull; [FAQ](#faq) &bull; [License](#license) ]

## Features

**IPAPatch** includes an template Xcode project, that provides following features:

- **Build & Run third-party ipa with your code injected**

  You can run your own code inside ipa file as a dynamic library. So you can change behavior of that app by utilizing Objective-C runtime.
  
  > *Presented an custom alert in Youtube app*
  >
  > <a href="https://camo.githubusercontent.com/c66c0d23a3ddeb40dc89624a90dd306546bcaa12/687474703a2f2f7778342e73696e61696d672e636e2f6c617267652f62656265646262356c7931666472653235613872316a323065623039773077672e6a7067" target="_blank"><img src="https://camo.githubusercontent.com/c66c0d23a3ddeb40dc89624a90dd306546bcaa12/687474703a2f2f7778342e73696e61696d672e636e2f6c617267652f62656265646262356c7931666472653235613872316a323065623039773077672e6a7067" alt="Youtube Hacked" data-canonical-src="http://wx4.sinaimg.cn/large/bebedbb5ly1fdre25a8r1j20eb09w0wg.jpg" style="max-width:100%;" width="360px"></a>
  
- **Step-by-step Debugging with lldb**

  You can debug third-party apps like your own. For example:
    
   - Step-by-Step debug your code inside other app
   - Set Breakpoints
   - Print objects in Xcode console with lldb
   <br/>
   
    > *Debugging Youtube with Xcode*
    > 
    > <a href="https://camo.githubusercontent.com/4b1650718581ccd3d2824d55342396d5fc1308fd/687474703a2f2f7778342e73696e61696d672e636e2f6c617267652f62656265646262356c7931666472656e776935646d6a3230657030616e77676b2e6a7067" target="_blank"><img src="https://camo.githubusercontent.com/4b1650718581ccd3d2824d55342396d5fc1308fd/687474703a2f2f7778342e73696e61696d672e636e2f6c617267652f62656265646262356c7931666472656e776935646d6a3230657030616e77676b2e6a7067" alt="Youtube Debugging" data-canonical-src="http://wx4.sinaimg.cn/large/bebedbb5ly1fdrenwi5dmj20ep0anwgk.jpg" style="max-width:100%;" width="360px"></a>
    

- **Link external frameworks**

  By linking existing frameworks, you can integrate third-party services to apps very easily, such as Reveal.
  
  > *Inspect Youtube by linking RevealServer.framework*
  >
  > <a href="https://camo.githubusercontent.com/ee35f8ef1c935174bb84b66f7e8888b0e0bee95f/687474703a2f2f7778322e73696e61696d672e636e2f6c617267652f62656265646262356c7931666472656271336667756a32306f703064627138702e6a7067" target="_blank"><img src="https://camo.githubusercontent.com/ee35f8ef1c935174bb84b66f7e8888b0e0bee95f/687474703a2f2f7778322e73696e61696d672e636e2f6c617267652f62656265646262356c7931666472656271336667756a32306f703064627138702e6a7067" alt="Youtube Integrated Reveal" data-canonical-src="http://wx2.sinaimg.cn/large/bebedbb5ly1fdrebq3fguj20op0dbq8p.jpg" style="max-width:100%;" width="540px"></a>

- **Generate distributable .ipa files**

  You can distribute your patch/work to your friends very easily, with IPAPatch generated modified version of .ipa files

    > *Modified version of Facebook.ipa created by IPAPatch*
    >
    > ![](http://wx1.sinaimg.cn/large/bebedbb5ly1fiyawu5q36j20gt07fgmr.jpg)

## Instructions

1. **Clone or Download This Project**
   
   Download this project to your local disk
   
2. **Prepare Decrypted IPA File**
  
   The IPA file you use need to be decrypted, you can get a decrypted ipa from a jailbroken device or download it directly from an ipa download site, such as http://www.iphonecake.com
  
3. **Replace Placeholder IPA**

   Replace the IPA file located at `IPAPatch/Assets/app.ipa` with yours, this is a placeholder file. The filename should remain `app.ipa` after replacing.
  
4. **Place External Resources/Frameworks (Optional)**
   
   Follow types of external file are supported:
   - **Frameworks**: 
     - External frameworks can be placed at `IPAPatch/Assets/Frameworks` folder. 
     - Frameworks will be linked automatically.     
     - For example `IPAPatch/Assets/Frameworks/RevealServer.framework`
   - **Dynamic Libraries**: 
     - External dynamic libraries can be placed at `IPAPatch/Assets/Dylibs` folder. 
     - Libraries will be linked automatically
   - **Resources/Bundles**: 
     - Other resources or bundles can be placed at `IPAPatch/Assets/Resources`
     - Resources will be copied directly to the main bundle of original app
  
5. **Configure Build Settings**

   - Open `IPAPatch.xcodeproj`
   - In the Project Editor, Select Target `IPAPatch-DummyApp`
   - `Display Name` defaults to "💊", this is used as prefix of the final display name.
   - Change `Bundle Identifier` to match your provisioning profiles
   - Fix signing issues if any.

6. **Configure IPPatch Options**

   - You can config IPAPatch's behavior with `Tools/options.plist`
   
        | Name | Description | Default |
        | --- | --- | --- |
        | RESTORE_SYMBOLS  | When `YES`, IPAPatch will try to restore symbol table from Mach-O for debugging propose (with tools from https://github.com/tobefuturer/restore-symbol, also thanks to @henrayluo and @dannion) | NO |
        | CREATE_IPA_FILE | When `YES`, IPAPatch will generate a ipa file on each build. Genrated file is located at `SRCROOT/Product` | NO |
        | IGNORE_UI_SUPPORTED_DEVICES | When `YES`, IPAPatch will delete `UISupportedDevices` from source app's `Info.plist` | NO |
        | REMOVE_WATCHPLACEHOLDER | When `YES`, IPAPatch will remove `com.apple.WatchPlaceholder` folder from source app's bundle | YES |
        | USE_ORIGINAL_ENTITLEMENTS | When `YES`, IPAPatch will use source app's entitlements to resign, you need to make sure your Provisioning Profile matches the entitlements, or you need to disable `AMFI` on target device | NO |

7. **Code Your Patch**

   The entry is at `+[IPAPatchEntry load]`, you can write code start from here. To change apps' behavior, You may need to use some method swizzling library, such as [steipete/Aspects](https://github.com/steipete/Aspects).

8. **Build and Run**

   Select a real device, and hit the "Run" button at the top-left corner of Xcode. The code your wrote and external frameworks you placed will inject to the ipa file automatically.

## Example

I created some demo project, which shows you how to use `IPAPatch`:

- Reveal + Youtube: 
  - https://github.com/Naituw/IPAPatch/releases/tag/1.0
- Cycript + Youtube (Idea from @phpmaple): 
  - https://github.com/Naituw/IPAPatch/releases/tag/1.0.1

## FAQ

- Q: Library not loaded with reason: `mach-o, but wrong architecture` ?
  - A: Try set `IPAPatch` target's `Valid Architectures` to match your ipa binary's architecture.

- Q: process launch failed: Unspecified (Disabled) ?
  - A: The ipa file use with IPAPatch must be decrypted, See step.2 of Instructions.

- Q: dyld: Symbol not found: XXX, Referenced from: XXX, Expected in: XXX/libswiftXXX.dylib
  - The swift version the framework you injecting use, is incompatible with the version of your Xcode

## License

#### IPAPatch

    IPAPatch is licensed under the MIT license.
      
    Copyright (c) 2017-present Wu Tian <wutian@me.com>.
      
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
      
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
      
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.


#### OPTOOL

    Copyright (c) 2014, Alex Zielenski
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#### fishhook

	Copyright (c) 2013, Facebook, Inc.
	All rights reserved.
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
	  * Redistributions of source code must retain the above copyright notice,
	    this list of conditions and the following disclaimer.
	  * Redistributions in binary form must reproduce the above copyright notice,
	    this list of conditions and the following disclaimer in the documentation
	    and/or other materials provided with the distribution.
	  * Neither the name Facebook nor the names of its contributors may be used to
	    endorse or promote products derived from this software without specific
	    prior written permission.
	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

