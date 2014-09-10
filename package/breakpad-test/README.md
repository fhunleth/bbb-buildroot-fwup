# Breakpad notes

Be sure to configure the following in Buildroot:

    BR2_ENABLE_DEBUG=y
    BR2_GOOGLE_BREAKPAD_ENABLE=y
    BR2_GOOGLE_BREAKPAD_INCLUDE_FILES="/usr/bin/breakpad-test /lib/libc-2.19-2014.05.so /lib/ld-2.19-2014.05.so"

By default, Buildroot doesn't compile with debug symbols so you need to enable
them. This shouldn't affect the target binary size since all binaries are
stripped anyway.

