TARGET := iphone:clang:latest:14.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = YouTube
THEOS_PACKAGE_SCHEME = rootless
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoThankYouTube

$(TWEAK_NAME)_FILES = $(shell find Sources -type f \( -name "*.x" -o -name "*.m" \))
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -ISources
$(TWEAK_NAME)_FRAMEWORKS = Foundation UIKit CoreFoundation UniformTypeIdentifiers

include $(THEOS_MAKE_PATH)/tweak.mk
