
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <sys/sysctl.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>
#import <substrate.h>

 int (*orig_ptrace)(int, pid_t, caddr_t, int) = NULL;
 int (*orig_getaddrinfo)( char*,  char*,   addrinfo*,  addrinfo**) = NULL;
 int (*orig_sysctl)(int*, u_int, void*, size_t*, void*, size_t) = NULL;

 void _Setup(void) {
    orig_ptrace = dlsym(RTLD_DEFAULT, "ptrace");
     (orig_ptrace) {
        MSHookFunction(orig_ptrace, (void*)^int(int req, pid_t pid, caddr_t addr, int data) {
             (req == 31)  0;
             orig_ptrace(req, pid, addr, data);
        }, NULL);
    }

    orig_getaddrinfo = dlsym(RTLD_DEFAULT, "getaddrinfo");
     (orig_getaddrinfo) {
        MSHookFunction(orig_getaddrinfo, (void*)^int( char* host,  char* serv,   addrinfo* hints,  addrinfo** res) {
             (host && (strstr(host, "report") || strstr(host, "analytics") || strstr(host, "tracking")))
                 EAI_NONAME;
             orig_getaddrinfo(host, serv, hints, res);
        }, NULL);
    }

    orig_sysctl = dlsym(RTLD_DEFAULT, "sysctl");
     (orig_sysctl) {
        MSHookFunction(orig_sysctl, (void*)^int(int* name, u_int namelen, void* oldp, size_t* oldlenp, void* newp, size_t newlen) {
            int ret = orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
             (namelen == 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID && name[3] == getpid()) {
                 kinfo_proc* info = (_*)oldp;
                 (info) info->kp_proc.p_flag &= ~0x800;
            }
             ret;
        }, NULL);
    }
}

 FVector { float X, Y, Z; };
 FRotator { float Pitch, Yaw, Roll; };

FVector (FVector src, FVector dst) {
    FVector ang;
    float dx = dst.X - src.X;
    float dy = dst.Y - src.Y;
    float dz = dst.Z - src.Z;
    float hyp = sqrtf(dx*dx + dy*dy);
    ang.X = -atan2f(dz, hyp) * 57.2957795f;
    ang.Y = atan2f(dy, dx) * 57.2957795f;
    ang.Z = 0;
     ang;
}

 UIView* g_Overlay = nil;

 void (void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow* w = nil;
         (UIWindowScene* scene  [UIApplication sharedApplication].connectedScenes) {
             (scene.activationState == UISceneActivationStateForegroundActive) {
                w = scene.windows.firstObject;
                ;
            }
        }
         (w) {
            g_Overlay = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
            g_Overlay.backgroundColor = [UIColor clearColor];
            g_Overlay.userInteractionEnabled = NO;
            g_Overlay.layer.zPosition = FLT_MAX;
            [w addSubview:g_Overlay];
        }
    });
}

 void (void) {
    setpriority(PRIO_PROCESS, getpid(), -20);
    setenv("PUBGM_SHADOW_QUALITY", "0", 1);
    setenv("PUBGM_POST_PROCESS", "0", 1);
    int bs = 524288;
    int s = socket(AF_INET, SOCK_STREAM, 0);
    setsockopt(s, SOL_SOCKET, SO_RCVBUF, &bs, (bs));
    setsockopt(s, SOL_SOCKET, SO_SNDBUF, &bs, 
               (bs));
    close(s);
}

__attribute__((constructor))
 void (void) {
    AntiBan_Setup();
    LagFix_Setup();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        ESP_Setup();
    });
}
