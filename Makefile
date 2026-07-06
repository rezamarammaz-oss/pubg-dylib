TARGET = iphone:clang:latest:15.0
ARCHS = arm64
include $(THEOS)/makefiles/common.mk
LIBRARY_NAME = AAIPUBG
AAIPUBG_FILES = main.mm
include $(THEOS_MAKE_PATH)/library.mk
