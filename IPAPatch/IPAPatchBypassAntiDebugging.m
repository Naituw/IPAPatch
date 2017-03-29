//
//  IPAPatchBypassAntiDebugging.m
//  IPAPatch
//
//  Created by wutian on 2017/3/23.
//  Copyright © 2017年 Weibo. All rights reserved.
//

#import "IPAPatchBypassAntiDebugging.h"
#import "fishhook.h"
#import <dlfcn.h>
#import <sys/sysctl.h>

#define TESTS_BYPASS 0

// Sources:
// https://www.coredump.gr/articles/ios-anti-debugging-protections-part-1/
// https://www.coredump.gr/articles/ios-anti-debugging-protections-part-2/
// https://www.theiphonewiki.com/wiki/Bugging_Debuggers

// Bypassing PT_DENY_ATTACH technique

static void * (*original_dlsym)(void *, const char *);

int fake_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data)
{
    return 0;
}

void * hooked_dlsym(void * __handle, const char * __symbol)
{
    if (strcmp(__symbol, "ptrace") == 0) {
        return &fake_ptrace;
    }
    
    return original_dlsym(__handle, __symbol);
}

static void disable_pt_deny_attach()
{
    original_dlsym = dlsym(RTLD_DEFAULT, "dlsym");
    rebind_symbols((struct rebinding[1]){{"dlsym", hooked_dlsym}}, 1);
}

// Bypassing sysctl debugger checking technique

static int (*original_sysctl)(int *, u_int, void *, size_t *, void *, size_t);

typedef struct kinfo_proc ipa_kinfo_proc;

int	hooked_sysctl(int * arg0, u_int arg1, void * arg2, size_t * arg3, void * arg4, size_t arg5)
{
    bool modify_needed = arg1 == 4 && arg0[0] == CTL_KERN && arg0[1] == KERN_PROC && arg0[2] == KERN_PROC_PID && arg2 && arg3 && (*arg3 == sizeof(ipa_kinfo_proc));
    
    if (modify_needed) {
        
        bool original_p_traced = false;
        {
            ipa_kinfo_proc * pointer = arg2;
            ipa_kinfo_proc info = *pointer;
            original_p_traced = (info.kp_proc.p_flag & P_TRACED) != 0;
        }
        
        int ret = original_sysctl(arg0, arg1, arg2, arg3, arg4, arg5);
        
        // keep P_TRACED if input value contains it
        if (!original_p_traced) {
            ipa_kinfo_proc * pointer = arg2;
            ipa_kinfo_proc info = *pointer;
            info.kp_proc.p_flag ^= P_TRACED;
            *pointer = info;
        }
        
        return ret;
        
    } else {
        return original_sysctl(arg0, arg1, arg2, arg3, arg4, arg5);
    }
}

static void disable_sysctl_debugger_checking()
{
    original_sysctl = dlsym(RTLD_DEFAULT, "sysctl");
    rebind_symbols((struct rebinding[1]){{"sysctl", hooked_sysctl}}, 1);
}

#if TESTS_BYPASS
// Tests
static void test_aniti_debugger();
#endif

@implementation IPAPatchBypassAntiDebugging

+ (void)load
{
    disable_pt_deny_attach();
    disable_sysctl_debugger_checking();
    
#if TESTS_BYPASS
    test_aniti_debugger();
#endif
}

@end

#if TESTS_BYPASS

typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);

#if !defined(PT_DENY_ATTACH)
#define PT_DENY_ATTACH 31
#endif

static void test_aniti_debugger()
{
    void* handle = dlopen(0, RTLD_GLOBAL | RTLD_NOW);
    ptrace_ptr_t ptrace_ptr = dlsym(handle, "ptrace");
    ptrace_ptr(PT_DENY_ATTACH, 0, 0, 0);
    dlclose(handle);
    
    int name[4];
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    
    info.kp_proc.p_flag = 0;
    
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();
    
    if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
        perror("sysctl");
        exit(-1);
    }
    bool debugging = ((info.kp_proc.p_flag & P_TRACED) != 0);
    
    NSCAssert(!debugging, @"Debug checking should be disabled");
}

#endif // TESTS_BYPASS
