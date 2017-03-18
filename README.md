![IPAPatch Hero](http://wx2.sinaimg.cn/large/bebedbb5ly1fdrbih316mj20f705iaah.jpg)

IPAPatch provides a simple way to patch iOS Apps, without need for jailbreaking.

### Features

**IPAPatch** includes an template Xcode project, that provides following features:

- **Build & Run third-party ipa with your code injected**

  You can run your own code inside ipa file as a dynamic library. So you can change behavior of that app by utilize Objective-C runtime.
  
  > *Presented an custom alert in Youtube app*
  >
  > ![Youtube Hacked](http://wx4.sinaimg.cn/large/bebedbb5ly1fdre25a8r1j20eb09w0wg.jpg)
  
- **Step-by-step Debugging with lldb**

  You can debug third-party apps like your own. For example:
    
   - Step-by-Step debug your code inside other app
   - Set Breakpoints
   - Print objects in Xcode console with lldb
   <br/>
   
    > *Debugging Youtube with Xcode*
    > 
    > ![Youtube Debugging](http://wx4.sinaimg.cn/large/bebedbb5ly1fdrenwi5dmj20ep0anwgk.jpg)
    

- **Link external frameworks**

  By linking existing frameworks, you can integrate third-party services to apps very easily, such as Reveal.
  
  > *Inspect Youtube by linking RevealServer.framework*
  >
  > ![Youtube Integrated Reveal](http://wx2.sinaimg.cn/large/bebedbb5ly1fdrebq3fguj20op0dbq8p.jpg) 


