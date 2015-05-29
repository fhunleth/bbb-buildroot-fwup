Intel Edison

Intro
=====

The Intel Edison is a small Intel Atom-based module. A number of carrier
modules exist for it, and these instructions should work if USB and a serial
console on ttyMFD2 are available.

How to build it
===============

Configure Buildroot
-------------------

The edison_simple_defconfig configuration is a minimal configuration with
all that is required to bring an Intel Edison up. You should base your
work on this defconfig:

  $ make edison_defconfig

Build the rootfs
----------------

Note: you will need to have access to the network, since Buildroot will
download the packages' sources.

You may now build your rootfs with:

  $ make

Result of the build
-------------------

After building, you should obtain this tree:

    output/images/
    +-- bzImage
    +-- edison.img
    +-- edison.xfstk.img
    +-- rootfs.ext4
    +-- u-boot.bin
    `-- uboot-env.bin

The script board/edison/mkedison.sh creates the two .img files by
concatenating the other files together. If you are able to program
the Edison's eMMC directly, use edison.img. The edison.xfstk.img file is a
slightly modified image suitable for Intel's xFSTK downloader.

Installation
============

Since the Buildroot image is small, it is possible to program the
important part of the eMMC if you currently have the stock Yocto Linux
installed. To do this, copy edison.img to the Edison and run:

  $ dd if=edison.img of=/dev/mmcblk0 bs=1M

The Buildroot image will load after a reboot.

More than likely, you will need to load the image via the Intel xFSTK
Downloader. This method has the advantage of working no matter what the state
of the eMMC memory is. Download and install the xFSTK programs from:

http://sourceforge.net/projects/xfstk/

You will also need the IFWI and DNX binaries from Intel's official Linux
package. These files can be found in the "Yocto complete image" on the Edison
downloads site:

http://www.intel.com/support/edison/sb/CS-035180.htm

The important files are:

    edison_dnx_fwr.bin
    edison_ifwi-dbg-00.bin
    edison_dnx_osr.bin

To program the Edison, connect the USB cable from the Edison to the PC. You
may also need to connect the console to reboot the Edison so that the firmware
loader in the bootloader can be run. It sometimes takes a couple reboots if
you have a good image already installed on the Edison. If the eMMC is corrupt,
the bootloader will wait. If the Edison is stuck in u-boot, hit CTRL-C and
reset.

On the PC, run:

    sudo xfstk-dldr-solo --gpflags 0x80000007 \
        --osimage output/images/edison.xfstk.img \
        --fwdnx edison_dnx_fwr.bin --fwimage edison_ifwi-dbg-00.bin \
        --osdnx edison_dnx_osr.bin

OSIP
====

The OSIP (OS Image Profile) header on the eMMC image is not well
documented on the Internet. It is a master boot record with some
additional information for where to find and how to load u-boot.
It also is read by the xfstk-dldr-solo when programming the device
through USB. The following information was found in Intel's Yocto
distribution for the Edison in the u-boot recipe.

    # Full OSIP header (size = 512 bytes)
    Offset   Size (bytes) Description
    0x000       4         OSIP Signature "$OS$"
    0x004       1         Reserved
    0x005       1         Header minor revision
    0x006       1         Header major revision
    0x007       1         Header checksum
    0x008       1         Number of pointers
    0x009       1         Number of images
    0x00a       2         Header size
    0x00c      20         Reserved
    0x020      24         1st bootable image descriptor (OSII)
    0x038      24         2nd bootable image descriptor (OSII)
    ...       ...         ...
    0x170      24         15th bootable image descriptor (OSII)
    0x188      48         Not used
    0x1B8       4         Disk signature
    0x1BC       2         Null (0x0000)
    0x1BE      16         1st primary partition descriptor
    0x1CE      16         2nd primary partition descriptor
    0x1DE      16         3rd primary partition descriptor
    0x1EE      16         4th primary partition descriptor
    0x1FE       1         0x55
    0x1FF       1         0xaa

Each OSII (OS Image Identifier) has the following format:

    Offset   Size (bytes) Description
    0x00        2         OS minor revision
    0x02        2         OS major revision
    0x04        4         Logical start block (units depend on
                          block size of media. 512 bytes for eMMC)
    0x08        4         DDR load address
    0x0c        4         Entry point
    0x10        4         Size of image (units of block size)
    0x14        1         Attribute
    0x15        3         Reserved



