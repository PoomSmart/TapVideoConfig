TARGET = iphone:11.2:10.0
PACKAGE_VERSION = 0.0.3

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TapVideoConfig
TapVideoConfig_FILES = Tweak.xm
TapVideoConfig_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk
