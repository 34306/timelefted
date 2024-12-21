export TARGET = iphone:clang:16.4:16.4
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TOOL_NAME = batt

$(TOOL_NAME)_FILES = main.m
$(TOOL_NAME)_FRAMEWORKS = Foundation IOKit
$(TOOL_NAME)_CFLAGS = -fobjc-arc
$(TOOL_NAME)_CODESIGN_FLAGS = -Sentitlements.plist
$(TOOL_NAME)_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
