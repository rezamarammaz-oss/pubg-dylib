```makefile
TARGET = iphone:clang:latest:15.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = AAIPUBG

AAIPUBG_FILES = main.mm
AAIPUBG_FRAMEWORKS = UIKit CoreGraphics QuartzCore Metal MetalKit AVFoundation ReplayKit Security
AAIPUBG_PRIVATE_FRAMEWORKS = CommonCrypto
AAIPUBG_LIBRARIES = substrate
AAIPUBG_CFLAGS = -fobjc-arc -O3

include $(THEOS_MAKE_PATH)/library.mk
```
