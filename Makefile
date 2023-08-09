GO_EASY_ON_ME=1

TARGET := iphone:7.0:2.0
ARCHS := armv6 arm64

#ADDITIONAL_OBJCFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Wink
Wink_FILES = Tweak.xm
Wink_FRAMEWORKS = UIKit CoreGraphics
Wink_LDFLAGS = -lapplist

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = WinkSettings
WinkSettings_FILES = Preferences.m
WinkSettings_INSTALL_PATH = /Library/PreferenceBundles
WinkSettings_FRAMEWORKS = UIKit
WinkSettings_PRIVATE_FRAMEWORKS = Preferences
WinkSettings_LDFLAGS = -lapplist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Wink.plist$(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
