# Buildroot and fwup Example

This project creates a simple image for the BBB using Buildroot and fwup.
Buildroot is used to build the Linux kernel and all programs. The fwup
utility is used to combine everything into a firmware file that can be
easily distributed and applied to an SDCard. A raw image is also built so
that `dd` or a similar tool can be used as well.

## Building

    make bbb_defconfig
    make
