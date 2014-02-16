THEOS_DEVICE_IP = 192.168.1.100

ARCHS = armv7 armv7s arm64
TARGET = iphone:latest:5.0

include theos/makefiles/common.mk

TWEAK_NAME = iOSRELottery
iOSRELottery_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Weibo"
