# Buildroot and fwup Example

This project creates a simple image for the BeagleBone Black using Buildroot and `fwup`.
Buildroot is used to build the Linux kernel and all programs. The fwup
utility is used to combine everything into a firmware file that can be
easily distributed and applied to an SDCard. A raw image is also built so
that `dd` or a similar tool can be used as well.

## Building

    make bbb_simple_defconfig
    make

The build products can be found in `buildroot/output/images`

## Installing

Insert an SDCard and note where it appears under Linux. If the SDCard is
automounted, make sure to `umount` everything that was mounted. Then run
the following, but replace `/dev/sdc` with the path to the SDCard.

    sudo dd if=buildroot/output/images/bbb.img of=/dev/sdc bs=1M

Insert the SDCard into a BeagleBone Black and watch it boot over the serial
port. Log in as `root`.
