ROOTLESS ?= 0

ifeq ($(ROOTLESS),1)
	TARGET = iphone:clang:latest:14.0
	ARCHS = arm64 arm64e
	THEOS_LAYOUT_DIR_NAME = layout-rootless
	THEOS_PACKAGE_SCHEME = rootless
else
	TARGET = iphone:clang:latest:9.0
endif
PACKAGE_VERSION = 1.0.0
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TapVideoConfig
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
