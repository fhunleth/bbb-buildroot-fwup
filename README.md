# Buildroot and fwup examples

This project contains two examples of using [Buildroot](http://buildroot.net/)
and [fwup](http://github.com/fhunleth/fwup) to create firmware images for the
BeagleBone Black. The first one simply creates a raw image that you can copy
directly to an SDCard using `dd(1)`. The second one demonstrates how `fwup` can
be used to create firmware update files (zip files with metadata) that can be
run directly on a BBB to upgrade the firmware running on it.

# Just building a raw firmware image

Sometimes it is useful to just build a raw image that can be written to an
SDCard with `dd(1)`. There's no need to think about firmware updates or anything
fancy. The `bbb_simple_defconfig` configuration is an example of this. It builds
a root file system and kernel that is a barebones Linux and Busybox build. To be
useful, one would need to add an application and probably a lot of libraries,
but that's not needed here.

The `fwup` utility is used to build a firmware update file out of everything. It
is then "applied" to an empty file called `bbb.img`. When it's "applied", it
writes the master boot record (MBR) to offset 0, creates a FAT partition for
uboot, and writes the rootfs to the right place. You can then use `bbb.img` with
`dd(1)`. The firmware update file, `bbb.fw`, can be ignored. It's just an
intermediate file.

The SDCard image that is created is defined in the file
`board/bbb/fwup-simple.conf`. Here's a more visual image of the layout of the
SDCard:

| Section        | Description |
| -------------- | ----------- |
| MBR            | Standard 512 byte master boot record |
| Boot partition | About 1 MiB; contains u-boot.img, uEnv.txt, etc. |
| Rootfs partition | Configured to be 128 MiB; contains rootfs as built by Buildroot |
| Partition 3    | Undefined |
| Partition 4    | Undefined |

As you can tell, there's a lot of unallocated space on the SDCard (we only use
the first 129 MB or so of space). By modifying `fwup-simple.conf` you can make
the boot or rootfs partitions bigger or create partitions 3 and 4.

## Building

If you're using Ubuntu, you may need to install some packages to make Buildroot
work. This should be sufficient:

    $ sudo apt-get install git g++ libncurses5-dev bc
    $ sudo apt-get install libc6:i386 libstdc++6:i386 zlib1g:i386 gcc-multilib # 64-bit Linux

After that, clone this project and run `make`:

    $ make bbb_simple_defconfig
    $ make

It can take some time to download and build everything so you may need to be
patient. The build products can be found in `buildroot/output/images`.

## Installing

Insert an SDCard on your PC and note where it appears under Linux. If the SDCard
is automounted, make sure to `umount` everything that was mounted. Then run the
following, but replace `/dev/sdc` with the path to the SDCard.

    $ sudo dd if=buildroot/output/images/bbb.img of=/dev/sdc bs=1M

Insert the SDCard into a BeagleBone Black, and watch it boot over the serial
port. Log in as `root`.

# On device firmware update

There are several strategies for updating firmware on device. For example, you
can update files directly on the rootfs, you can have a small firmware update
program on a dedicated partition that knows how to update the main partition, or
you can have two locations on the SDCard/eMMC and ping/pong between them. This
section describes the latter setup. The `fwup` configuration can be found in
`board/bbb/fwup-pingpong.conf` and it creates a SDCard/eMMC layout like the
following:

| Section        | Description |
| -------------- | ----------- |
| MBR            | Standard 512 byte master boot record |
| Boot partition | About 1 MiB; contains u-boot.img, uEnv.txt, etc. |
| Rootfs A partition | Configured to be 128 MiB; contains rootfs as built by Buildroot |
| Rootfs B partition | Configured to be 128 MiB; unused until the firmware update |
| Application data partition | FAT32 partition used for demonstration. Application data that should survive firmware updates would be put here. |

The way it works is that uboot boots Linux from Rootfs A. At a later point in
time, the user applies an update. This gets written to the Rootfs B partition.
After all of the data gets written, the MBR will be updated to make uboot boot
Linux from the Rootfs B partition. This has a nice property in that if the user
pulls the power or hits cancel midway during the update, the system will boot
from Rootfs A like the firmware update never happened. Likewise, if an error is
detected midway into the firmware update process, no damage is done. Obviously, you can
still brick the system if the firmware update is valid, but the software in it
is buggy. To recover from that, you could create a uboot script that boots from
the opposite rootfs partition if you hold down a button or something. That is
not demonstrated here.

## Building the demo

For the demo, we need an two firmware files, "v1" and "v2". We'll install the
"v1" firmware and then upgrade to the "v2" firmware.

NOTE: Building takes a while. If you want to cheat, just copy the firmware files
that I made from the `prebuilt` directory.

    # Build the "v1" firmware
    $ make realclean
    $ make bbb_fwup1_defconfig
    $ make

    # save the "v1" firmware
    $ cp buildroot/output/images/bbb.fw bbb-v1.fw

    # Build the "v2" firmware
    $ make realclean
    $ make bbb_fwup2_defconfig
    $ make

    # save the "v2" firmware
    $ cp buildroot/output/images/bbb.fw bbb-v2.fw

Insert an SDCard into your PC (via a USB multireader or other device) so that it
can be programmed with the "v1" firmware. On my PC, it shows up as `/dev/sdc`:

    # unmount any file systems that were automounted
    $ umount /media/fhunleth/*

    # program the SDCard with v1
    $ sudo buildroot/output/host/usr/bin/fwup -a -i bbb-v1.fw -t complete
    Use 3.64 GiB memory card found at /dev/sdc? [y/N] y

`fwup` will try to detect the SDCard and will ask for confirmation before
writing to it. If you have multiple devices that look like SDCards or `fwup` doesn't
detected it, you may need to add `-d /dev/sdc` or similar to the command line.
The `complete` parameter specifies which task from the `fwup-pingpong.conf` file
to run. In this case, we want a complete image that writes the MBR, bootloader
partition, rootfs, and clears out all application data. When we do updates, we
don't want to overwrite the bootloader partition or the application data, so the
upgrade task doesn't do this. You can configure `fwup` to update them anyway if
you want. Also note that we could have programmed the `bbb.img` file here like
we did in the simple example at the top. Using `fwup` can be faster since it
doesn't have to write zeros to fill in the gaps between partitions.

Next, mount the new filesystems on the SDCard on your PC. I find it easiest to
unplug and plug the SDCard back into the PC so that it automounts. Three
filesystems should mount, the boot partition, the rootfs, and a big empty
partition for application data. Copy both firmware update files to the
application data partition.

    # My SDCard's 4th partition got automounted as 4507-9E5C1, but
    # this changes. Check that you're not copying to the boot or rootfs
    # before doing this on your system. I also get confused on the BBB
    # whether I'm using the eMMC or the SDCard, so I'm creating an "sdcard" file
    # here as a sanity check.

    $ cp *.fw /media/fhunleth/4507-9E5C1
    $ touch /media/fhunleth/4507-9E5C1/sdcard
    $ ls -las /media/fhunleth/4507-9E5C1
    total 9227
       1 drwx------  2 fhunleth fhunleth     512 Sep  7 16:47 .
       4 drwxr-x---+ 6 root     root        4096 Sep  7 16:42 ..
    4611 -rw-r--r--  1 fhunleth fhunleth 4721489 Sep  7 16:43 bbb-v1.fw
    4611 -rw-r--r--  1 fhunleth fhunleth 4721373 Sep  7 16:43 bbb-v2.fw
       0 -rw-r--r--  1 fhunleth fhunleth       0 Sep  7 16:47 sdcard

    $ umount /media/fhunleth/*

After unmounting the SDCard, plug it into the BBB and boot off it. The console
is accessible via the UART. Here's what you should see when you boot and login:

    This image was created using the bbb_fwup1_defconfig.
    buildroot login: root
    #

Mount the application data partition:

    # mount /dev/mmcblk0p4 /mnt
    # ls /mnt
    bbb-v1.fw  bbb-v2.fw  sdcard

At this point, it's possible to demo a firmware update on the BBB. We're running
the "v1" firmware (`cat /etc/issue` if unsure) and we want to apply the "v2"
firmware. Run the following:

    # fwup -a -d /dev/mmcblk0 -i /mnt/bbb-v2.fw -t upgrade

This runs the `upgrade` task on `/dev/mmcblk0`. `fwup` is smart enough to detect
that we're running off the Rootfs A partition (i.e., the 2nd partition) so it writes the
"v2" firmware to the Rootfs B partition (i.e., the 3rd partition). The update is
NOT finished, so if you reboot now, you won't get the update. You must finalize
the upgrade. I like this since it allows me to change my mind, but if you don't
need this ability, you can update the `fwup-pingpong.conf` file to not have a
two step upgrade. To run the second step, you'll find that the first call to
`fwup` created a file on `/tmp`. Run `fwup` on it to finalize the upgrade:

    # ls -las /tmp/finalize.fw
         4 -rw-r--r--    1 root     root          1366 Jan  1 01:47 /tmp/finalize.fw
    # fwup -a -d /dev/mmcblk0 -i /tmp/finalize.fw -t on-reboot
    # reboot

After it reboots, you should see the following:

    This image was created using the bbb_fwup2_defconfig.
    buildroot login:

This `bbb_fwup2_defconfig` part tells you that you are now running the "v2"
software. Even though I only changed `/etc/issue` between the firmware versions, a
whole new rootfs was installed. This was overkill for this minor change, but in
a real scenerio where small parts of the Linux kernel, the application, and
random changes to system utilities and libraries, upgrading the whole rootfs is
not unreasonable.

If you want to verify what happened, place the SDCard into your PC. You should
see two rootfs file systems and you can verify that one of them has a
`/etc/issue` file with the "v1" contents and the other rootfs has a `/etc/issue`
with the "v2" contents.

## Programming the eMMC

On the BBB, it's convenient to run off the eMMC. Programming it after booting
from an SDCard is similar to programming the SDCard from your PC - just apply a
`complete` firmware image to the eMMC. Assuming that you worked through the above
example, boot from the SDCard and run the following:

    # mount /dev/mmcblk0p4 /mnt
    # fwup -a -d /dev/mmcblk1 -i /mnt/bbb-v2.fw -t complete
    # poweroff

Now remove the SDCard and press the reset button. The BBB should boot from eMMC.
If you insert the SDCard back in and mount the 4th partition, you can run
through the above instructions to apply the "v1" firmware to the eMMC if you'd
like:

    # mount /dev/mmcblk1p4 /mnt
    # ls /mnt
    bbb-v1.fw  bbb-v2.fw  sdcard
    # fwup -a -d /dev/mmcblk0 -i /mnt/bbb-v1.fw -t upgrade
    # fwup -a -d /dev/mmcblk0 -i /tmp/finalize.fw -t on-reboot
    # poweroff

Now remove the SDCard, press reset and verify that the "v1" firmware is
running. Do it again with "v2" if you'd like.
