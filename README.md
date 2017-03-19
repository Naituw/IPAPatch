![IPAPatch Logo](http://wx1.sinaimg.cn/large/bebedbb5ly1fdrgg0v1hjj20e205qdgi.jpg)

IPAPatch provide a simple way to patch iOS Apps, without needing to jailbreak.

[ [Features](#features) &bull; [Instructions](#instructions) &bull; [Example](#example) &bull; [License](#license) ]

## Features

**IPAPatch** includes an template Xcode project, that provides following features:

- **Build & Run third-party ipa with your code injected**

  You can run your own code inside ipa file as a dynamic library. So you can change behavior of that app by utilize Objective-C runtime.
  
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

## Instructions

1. **Clone or Download This Project**
   
   Download this project to your local disk
   
2. **Prepare Decrypted IPA File**
  
   The IPA file you use need to be decrypted, you can get decrypted ipa from jailbroken device or download directly from ipa download site, such as http://www.iphonecake.com
  
3. **Replace Placeholder IPA**

   Replace the IPA file located at `IPAPatch/Assets/app.ipa` with yours, this is a placeholder file. The filename should remain `app.ipa` after replacing.
  
4. **Place External Frameworks (Optional)**
  
   External frameworks can be placed at `IPAPatch/Assets/Frameworks` folder. Frameworks will linked automatically.
  
   For example `IPAPatch/Assets/Frameworks/RevealServer.framework`
  
5. **Configure Build Settings**

   - Open `IPAPatch.xcodeproj`
   - In the Project Editor, Select Target `IPAPatch-DummyApp`
   - `Display Name` defaults to "💊", this is used as prefix of final display name.
   - Change `Bundle Identifier` to match your provisioning profiles
   - Fix signing issues if any.

6. **Code Your Patch**

   The entry is at `+[IPAPatchEntry load]`, you can write code start from here. To change apps' behavior, You may need to use some method swizzling library, such as [steipete/Aspects](https://github.com/steipete/Aspects).

7. **Build and Run**

   Select an real device, and hit "Run" button at the top-left corner of Xcode. The code your wrote and external frameworks you placed will inject to the ipa file automatically.

## Example

I created a demo project, shows you how to integrate Reveal into Youtube, which can be found here:
https://github.com/Naituw/IPAPatch/releases/tag/1.0

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

