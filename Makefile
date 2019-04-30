ARCHS = arm64

PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SPDMLite
SPDMLite_FILES = Tweak.xm
SPDMLite_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += spdmliteprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
