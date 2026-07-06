#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <sys/sysctl.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>
#import <substrate.h>

static BOOL g_Aimbot = YES;
static int g_FOV = 15;
static int g_Smooth = 12;

// ====== ANTI-BAN CORE ======
static int (*orig_ptrace)(int, pid_t, caddr_t, int) = NULL;

static void AntiBan_Setup(void) {
    // 1. Anti-Debug: hook ptrace
    orig_ptrace = (int(*)(int, pid_t, caddr_t, int))dlsym(RTLD_DEFAULT, "ptrace");
    if (orig_ptrace) {
        MSHookFunction((void*)orig_ptrace, (void*)^int(int req, pid_t pid, caddr_t addr, int data) {
            return (req == 31) ? 0 : orig_ptrace(req, pid, addr, data);
        }, NULL);
    }
    
    // 2. Block report servers
    int (*orig_getaddrinfo)(const char*, const char*, const struct addrinfo*, struct addrinfo**);
    orig_getaddrinfo = (int(*)(const char*, const char*, const struct addrinfo*, struct addrinfo**))dlsym(RTLD_DEFAULT, "getaddrinfo");
    if (orig_getaddrinfo) {
        MSHookFunction((void*)orig_getaddrinfo, (void*)^int(const char* h, const char* s, const struct addrinfo* hints, struct addrinfo** r) {
            if (h && (strstr(h, "report") || strstr(h, "analytics") || strstr(h, "tracking"))) return EAI_NONAME;
            return orig_getaddrinfo(h, s, hints, r);
        }, NULL);
    }
    
    // 3. Hide traced flag
    int (*orig_sysctl)(int*, u_int, void*, size_t*, void*, size_t);
    orig_sysctl = (int(*)(int*, u_int, void*, size_t*, void*, size_t))dlsym(RTLD_DEFAULT, "sysctl");
    if (orig_sysctl) {
        MSHookFunction((void*)orig_sysctl, (void*)^int(int* name, u_int nl, void* oldp, size_t* ol, void* np, size_t nl2) {
            int r = orig_sysctl(name, nl, oldp, ol, np, nl2);
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
    FVector ang;
    float dx = dst.X - src.X;
    float dy = dst.Y - src.Y;
    float dz = dst.Z - src.Z;
    float hyp = sqrtf(dx*dx + dy*dy);
    ang.X = -atan2f(dz, hyp) * 57.2957795f;
    ang.Y = atan2f(dy, dx) * 57.2957795f;
    ang.Z = 0;
    return ang;
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
void (void) {
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
stati void Init(void) {
    AntiBan_Setup();
    LagFix_Setup();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        ESP_Setup();
    });
}
