#import <substrate.h>
#import <dlfcn.h>
#import <sys/sysctl.h>

__attribute__((constructor))
static void init_func() {
    void *ptrace_ptr = dlsym(RTLD_DEFAULT, "ptrace");
    if (ptrace_ptr) {
        MSHookFunction(ptrace_ptr, (void *)(int (*)(int, pid_t, caddr_t, int))^int(int req, pid_t a, caddr_t b, int c) {
            return (req == 31) ? 0 : 0;
        }, NULL);
    }
    setpriority(PRIO_PROCESS, getpid(), -20);
}
