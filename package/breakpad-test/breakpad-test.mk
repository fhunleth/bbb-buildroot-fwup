################################################################################
#
# breakpad-test
#
################################################################################

BREAKPAD_TEST_SOURCE =
HOST_BREAKPAD_TEST_SOURCE =

BREAKPAD_TEST_VERSION = 0.1
BREAKPAD_TEST_LICENSE = GPLv2

define BREAKPAD_TEST_BUILD_CMDS
	$(TARGET_CXX) $(TARGET_CXXFLAGS) $(TARGET_LDFLAGS) \
	        -I/home/fhunleth/experiments/simplebbb/buildroot/output/build/google-breakpad-1320/src \
		../package/breakpad-test/breakpad-test.cpp \
		../package/breakpad-test/crash.cpp \
		-lbreakpad_client \
		-pthread \
		-o $(@D)/breakpad-test
endef

define BREAKPAD_TEST_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/breakpad-test $(TARGET_DIR)/usr/bin/breakpad-test
endef

$(eval $(generic-package))
