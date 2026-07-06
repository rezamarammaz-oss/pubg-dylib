#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/vm_map.h>
#import <sys/sysctl.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <substrate.h>

static BOOL g_Aimbot = YES;
static int g_FOV = 15;
static int g_Smooth = 12;

// ====== ANTI-BAN CORE ======
static void AntiBan_Setup(void) {
    // 1. Anti-Debug
    void* ptrace_ptr = dlsym(RTLD_DEFAULT, "ptrace");
    if (ptrace_ptr) {
        MSHookFunction(ptrace_ptr, (void*)^int(int req, pid_t pid, caddr_t addr, int data) {
            return (req == 31) ? 0 : ptrace(req, pid, addr, data);
        }, NULL);
    }
    
    // 2. Block report servers
    void* getaddrinfo_ptr = dlsym(RTLD_DEFAULT, "getaddrinfo");
    if (getaddrinfo_ptr) {
        MSHookFunction(getaddrinfo_ptr, (void*)^int(const char* h, const char* s, const struct addrinfo* hints, struct addrinfo** r) {
            if (h && (strstr(h, "report") || strstr(h, "analytics") || strstr(h, "tracking"))) return EAI_NONAME;
            return getaddrinfo(h, s, hints, r);
        }, NULL);
    }
    
    // 3. Hide traced flag
    void* sysctl_ptr = dlsym(RTLD_DEFAULT, "sysctl");
    if (sysctl_ptr) {
        MSHookFunction(sysctl_ptr, (void*)^int(int* name, u_int nl, void* oldp, size_t* ol, void* np, size_t nl2) {
            int r = sysctl(name, nl, oldp, ol, np, nl2);
            if (nl == 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID && name[3] == getpid()) {
                struct kinfo_proc* info = (struct kinfo_proc*)oldp;
                if (info) info->kp_proc.p_flag &= ~0x800;
            }
            return r;
        }, NULL);
    }
}

// ====== AIMBOT ======
struct FVector { float X, Y, Z; };
struct FRotator { float Pitch, Yaw, Roll; };

static FVector CalcAngle(FVector src, FVector dst) {
    FVector d = {dst.X - src.X, dst.Y - src.Y, dst.Z - src.Z};
    float h = sqrtf(d.X*d.X + d.Y*d.Y);
    return {-atan2f(d.Z, h) * 57.2957795f, atan2f(d.Y, d.X) * 57.2957795f, 0};
}

// ====== ESP OVERLAY ======
static UIView* g_Overlay = nil;

static void ESP_Setup(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow* w = nil;
        for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                w = scene.windows.firstObject;
                break;
            }
        }
        if (w) {
            g_Overlay = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
            g_Overlay.backgroundColor = [UIColor clearColor];
            g_Overlay.userInteractionEnabled = NO;
            g_Overlay.layer.zPosition = FLT_MAX;
            [w addSubview:g_Overlay];
        }
    });
}

// ====== LAG FIX ======
static void LagFix_Setup(void) {
    setpriority(PRIO_PROCESS, getpid(), -20);
    setenv("PUBGM_SHADOW_QUALITY", "0", 1);
    setenv("PUBGM_POST_PROCESS", "0", 1);
    int bs = 524288;
    int s = socket(AF_INET, SOCK_STREAM, 0);
    setsockopt(s, SOL_SOCKET, SO_RCVBUF, &bs, sizeof(bs));
    setsockopt(s, SOL_SOCKET, SO_SNDBUF, &bs, sizeof(bs));
    close(s);
}

// ====== LAUNCH ======
__attribute__((constructor))
static void Init(void) {
    AntiBan_Setup();
    LagFix_Setup();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        ESP_Setup();
    });
}
