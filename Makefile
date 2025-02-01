ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
TARGET = iphone:clang:latest:15.0
else
TARGET = iphone:clang:14.5:13.0
export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/
endif
PACKAGE_VERSION = 1.0.2
INSTALL_TARGET_PROCESSES = Camera

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TapVideoConfig
$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
